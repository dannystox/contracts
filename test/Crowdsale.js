const BigNumber = require('bignumber.js')
const Promise = require('bluebird')

const Milestones = artifacts.require("../contracts/milestones/BasicMilestones.sol")
const Forecasting = artifacts.require("../contracts/forecasts/BasicForecasting.sol")
const Crowdsale = artifacts.require("../contracts/crowdsale/BasicCrowdsale.sol")

const crypto = require('crypto')
const Chance = require('chance')
const parser = require('../helpers/parser')
const arrayHelper = require('../helpers/arrays')
const errors = require('../helpers/errors')
const time = require('../helpers/time')
const miner = require('../helpers/miner')

contract('Crowdsale', () => {
  const creator = web3.eth.accounts[0]
  let chance = new Chance()

  let milestones, forecasting, crowdsale
  let startTime, rewardPercet

  let milestonesItems = []
  let participiants = []
  let crowdsaleParams = {}
  const timestamps = []

  const vestingMonthes = 26

  let crowdsaleLockTime, crowdsaleStartTime, crowdsaleEndTime

  before('Contract Creation', () => {
    let now = new Date()
    now.setHours(1,0,0,0)

    for (let i = 0; i < vestingMonthes; i++) {
      now.setMonth(now.getMonth() + 1, 1)

      timestamps.push(time.toSeconds(now.getTime()))
    }

    return time.blockchainTime(web3).then(time => {
      startTime = time

      return Milestones.new(creator, false)
    }).then(_milestones => {
      milestones = _milestones

      milestonesItems.push({
        amount: web3.toWei(1, 'ether'),
        items: '0x' + crypto.randomBytes(32).toString('hex')
      })

      // add milestones and set limittation to two hours ago
      for (let i = 0; i < 3; i++) {
        const milestone = {
          amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
          items: '0x' + crypto.randomBytes(32).toString('hex')
        }

        milestonesItems.push(milestone)
      }

      return Promise.mapSeries(milestonesItems, milestone => {
        return milestones.add.sendTransaction(milestone.amount, milestone.items, {
          from: creator
        })
      }).then(() => {
        const milestoneStartTime = startTime
        const milestoneEndTime = startTime + 3600

        return milestones.setLimitations.sendTransaction(milestoneStartTime, milestoneEndTime)
      })
    }).then(() => {
      const forecastingStartTime = startTime + 3600
      const forecastingEndTime = startTime + 7200
      rewardPercent = chance.integer({min: 1, max: 100000000 })

      return Forecasting.new(
        forecastingStartTime,
        forecastingEndTime,
        rewardPercent,
        '0x0',
        milestones.address,
        false
      )
    }).then(_forecasting => {
      forecasting = _forecasting

      return Crowdsale.new(
        creator,
        web3.eth.accounts[9],
        "Wings",
        "WINGS",
        milestones.address,
        forecasting.forecasting,
        10,
        rewardPercent
      )
    }).then(_crowdsale => {
      crowdsale = _crowdsale
    })
  })

  it('Shouldnt create tokens while crowdsale not alive', () => {
    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: web3.eth.accounts[0],
        to: crowdsale.address,
        value: web3.toWei(1, 'ether'),
        gas: 90000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      throw new Error('Shouldnt happen')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.totalCollected.call()
    }).then(totalCollected => {
      assert.equal(totalCollected.toNumber(), 0)
    })
  })

  it('Contract balance still should be equal zero', () => {
    return crowdsale.contractBalance.call().then(balance => {
      assert.equal(balance.toNumber(), 0)
    })
  })

  it('User balance should be equal 0 after sending eth before crowfunding period hasnt started', () => {
    return crowdsale.balanceOf(web3.eth.accounts[0]).then(balance => {
      assert.equal(balance.toNumber(), 0)
    })
  })

  it('Initial price should equal 10 ETH' , () => {
    return crowdsale.getPrice.call().then(price => {
      assert.equal(price.toNumber(), 10)
    })
  })

  it('Should allow to add vesting account now', () => {
    crowdsaleParams.vestingAccounts = []

    for (let i = 1; i < 3; i++) {
      crowdsaleParams.vestingAccounts.push({
        account: web3.eth.accounts[i],
        initial: web3.toWei(100, 'ether'),
        payment: web3.toWei(50, 'ether')
      })
    }

    return Promise.each(crowdsaleParams.vestingAccounts, vestingAccount => {
      return crowdsale.addVestingAccount(vestingAccount.account, vestingAccount.initial, vestingAccount.payment).then(() => {
        return Promise.each(timestamps, timestamp => {
          return crowdsale.addVestingAllocation(vestingAccount.account, timestamp)
        })
      })
    })
  })

  it('Should contains vesting accounts', () => {
    return Promise.each(crowdsaleParams.vestingAccounts, vestingAccount => {
      return crowdsale.getVestingAccount.call(vestingAccount.account).then(rawVestingData => {
        const parsedVesting = parser.parsePreminer(rawVestingData)

        assert.equal(vestingAccount.payment.toString(10), parsedVesting.payment.toString(10))
        assert.equal(0, parsedVesting.latestAllocation.toNumber())
        assert.equal(timestamps.length, parsedVesting.allocationsCount.toNumber())

        return crowdsale.balanceOf.call(vestingAccount.account)
      }).then(balance => {
        assert.equal(vestingAccount.initial.toString(10), balance.toString(10))
      })
    })
  })

  it('Shouldnt allow to release premine now', () => {
    return crowdsale.releaseVestingAllocation({
      from: crowdsaleParams.vestingAccounts[0].account
    }).then(() => {
      throw new Error('Shouldnt be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.balanceOf.call(crowdsaleParams.vestingAccounts[0].account)
    }).then(balance => {
      assert.equal(crowdsaleParams.vestingAccounts[0].initial.toString(10), balance.toString(10))
    })
  })

  it('Shouldnt allow to transfer vested tokens now', () => {
    return crowdsale.transfer(web3.eth.accounts[0], web3.toWei(1, 'ether'), {
      from: crowdsaleParams.vestingAccounts[0].account
    }).then(() => {
      throw new Error('Cant be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return Promise.join(
        crowdsale.balanceOf.call(web3.eth.accounts[0]),
        crowdsale.balanceOf.call(crowdsaleParams.vestingAccounts[0].account),
        (toBalance, fromBalance) => {
          assert.equal(toBalance.toString(10), '0')
          assert.equal(fromBalance.toString(10), crowdsaleParams.vestingAccounts[0].initial.toString(10))
        }
      )
    })
  })

  it('It should move time before limitations and still allow to change data', () => {
    crowdsaleLockTime = startTime + 3600
    crowdsaleStartTime = startTime + 7200
    crowdsaleEndTime = startTime + 10800

    return crowdsale.setLimitations(crowdsaleLockTime, crowdsaleStartTime, crowdsaleEndTime).then(() => {
      return Promise.join(
        crowdsale.lockDataTimestamp.call(),
        crowdsale.startTimestamp.call(),
        crowdsale.endTimestamp.call(),
        (lock, start, end) => {
          assert.equal(lock.toNumber(), crowdsaleLockTime)
          assert.equal(start.toNumber(), crowdsaleStartTime)
          assert.equal(end.toNumber(), crowdsaleEndTime)
        }
      )
    })
  })

  it('Still should allow to vesting account', () => {
    const vestingAccount = {
      account: web3.eth.accounts[3],
      initial: web3.toWei(100, 'ether'),
      payment: web3.toWei(50, 'ether')
    }

    crowdsaleParams.vestingAccounts.push(vestingAccount)

    return crowdsale.addVestingAccount(vestingAccount.account, vestingAccount.initial, vestingAccount.payment).then(() => {
      return Promise.each(timestamps, timestamp => {
        return crowdsale.addVestingAllocation(vestingAccount.account, timestamp)
      })
    })
  })

  it('Should contains added account', () => {
    const length = crowdsaleParams.vestingAccounts.length
    const vestingAccount = crowdsaleParams.vestingAccounts[length-1]

    return crowdsale.getVestingAccount.call(vestingAccount.account).then(rawVestingData => {
      const parsedVesting = parser.parsePreminer(rawVestingData)

      assert.equal(vestingAccount.payment.toString(10), parsedVesting.payment.toString(10))
      assert.equal(0, parsedVesting.latestAllocation.toNumber())
      assert.equal(timestamps.length, parsedVesting.allocationsCount.toNumber())

      return crowdsale.balanceOf.call(vestingAccount.account)
    }).then(balance => {
      assert.equal(vestingAccount.initial.toString(10), balance.toString(10))
    })
  })

  it('Should allow to add new price change', () => {
    return crowdsale.addPriceChange(startTime+9000, 5)
  })

  it('Shouldnt allow to move vested tokens now', () => {
    return crowdsale.transfer(web3.eth.accounts[0], web3.toWei(1, 'ether'), {
      from: crowdsaleParams.vestingAccounts[0].account
    }).then(() => {
      throw new Error('Cant be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return Promise.join(
        crowdsale.balanceOf.call(web3.eth.accounts[0]),
        crowdsale.balanceOf.call(crowdsaleParams.vestingAccounts[0].account),
        (toBalance, fromBalance) => {
          assert.equal(toBalance.toString(10), '0')
          assert.equal(fromBalance.toString(10), crowdsaleParams.vestingAccounts[0].initial.toString(10))
        }
      )
    })
  })

  it('Shouldnt allow to buy tokens', () => {
    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: web3.eth.accounts[0],
        to: crowdsale.address,
        value: web3.toWei(1, 'ether'),
        gas: 90000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      throw new Error('Shouldnt happen')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.totalCollected.call()
    }).then(totalCollected => {
      assert.equal(totalCollected.toNumber(), 0)
    })
  })

  it('Shouldnt allow to withdraw collected eth', () => {
    return crowdsale.withdraw(0).then(() => {
      throw new Error('Shouldnt be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Move time to lock time', () => {
    return time.move(web3, 3600).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3)
    }).then(blockchainTime => {
      assert.equal(blockchainTime > crowdsaleLockTime, true)
    })
  })

  it('Should be not possible to change anything', () => {
    const vestingAccount = {
      account: web3.eth.accounts[3],
      initial: web3.toWei(100, 'ether'),
      payment: web3.toWei(50, 'ether'),
      gas: 90000
    }

    return crowdsale.addVestingAccount(vestingAccount.account, vestingAccount.initial, vestingAccount.payment).then(() => {
      throw new Error('Cant be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.addPriceChange(startTime+9500, 5)
    }).then(() => {
      throw new Error('Shouldnt be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.addVestingAllocation(crowdsaleParams.vestingAccounts[0].payment, timestamps[timestamps.length-1] + 2592000)
    }).then(() => {
      throw new Error('Shouldnt be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Move time to crowdsale time', () => {
    return time.move(web3, 3600).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3)
    }).then(blockchainTime => {
      assert.equal(blockchainTime > crowdsaleStartTime, true)
    })
  })

  it('Should return correct price', () => {
    return crowdsale.getPrice.call().then(price => {
      assert.equal(price.toNumber(), 10)
    })
  })

  it('Should buy tokens', () => {
    participiants.push({
      account: web3.eth.accounts[4],
      balance: new BigNumber(web3.toWei(1, 'ether')).mul(10)
    })

    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: participiants[0].account,
        to: crowdsale.address,
        value: web3.toWei(1, 'ether'),
        gas: 130000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      return crowdsale.totalCollected.call()
    }).then(totalCollected => {
      assert.equal(totalCollected.toString(10), web3.toWei(1, 'ether').toString(10))
      return crowdsale.balanceOf(web3.eth.accounts[4])
    }).then(balance => {
      assert.equal(balance.toString(10), participiants[0].balance.toString(10))
    })
  })

  it('Shouldnt possible to move tokens while crowdsale alive', () => {
    return crowdsale.transfer(web3.eth.accounts[5], participiants[0].balance, {
      from: participiants[0].account
    }).then(() => {
      throw new Error('Cant be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.balanceOf(participiants[0].account)
    }).then(balance => {
      assert.equal(balance.toString(10), participiants[0].balance.toString(10))
    })
  })

  it('Change token price', () => {
    return time.move(web3, 1800).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return crowdsale.getPrice()
    }).then(price => {
      assert.equal(price.toNumber(), 5)
    })
  })

  it('Should calculate token bying by new price', () => {
    participiants.push({
      account: web3.eth.accounts[5],
      balance: new BigNumber(web3.toWei(2, 'ether')).mul(5)
    })

    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: participiants[1].account,
        to: crowdsale.address,
        value: web3.toWei(2, 'ether'),
        gas: 130000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      return crowdsale.totalCollected.call()
    }).then(totalCollected => {
      assert.equal(totalCollected.toString(10), web3.toWei(3, 'ether').toString(10))
      return crowdsale.balanceOf(web3.eth.accounts[5])
    }).then(balance => {
      assert.equal(balance.toString(10), participiants[1].balance.toString(10))
    })
  })

  it('Shouldnt allow to withdraw ETH now', () => {
    return crowdsale.withdraw(web3.toWei(1, 'ether')).then(() => {
      throw new Error('Shouldnt be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.multisig.call()
    }).then(multisig => {
      return crowdsale.balanceOf(multisig)
    }).then(balance => {
      assert.equal(balance.toNumber(), 0)
    })
  })

  it('Should complete crowdsale', () => {
    return time.move(web3, 1800).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3)
    }).then(blockchainTime => {
      assert.equal(blockchainTime > crowdsaleEndTime, true)
    })
  })

  it('Crowdsale should contain more ETH to be successful then first milestone', () => {
    return milestones.get(0).then(rawMilestoneData => {
      const milestone = parser.parseMilestone(rawMilestoneData)

      assert.equal(milestone.amount.toString(10), milestonesItems[0].amount.toString(10))

      return crowdsale.totalCollected.call().then(collected => {
        assert.equal(collected.gt(milestone.amount), true)
      })
    })
  })

  it('Shouldnt allow to buy tokens after crowdsale completed', () => {
    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: web3.eth.accounts[6],
        to: crowdsale.address,
        value: web3.toWei(1, 'ether'),
        gas: 90000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      throw new Error('Shouldnt happen')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.totalCollected.call()
    }).then(totalCollected => {
      assert.equal(totalCollected.toString(10), web3.toWei(3, 'ether').toString(10))

      return crowdsale.balanceOf(web3.eth.accounts[6])
    }).then(balance => {
      assert.equal(balance.toNumber(), 0)
    })
  })

  it('Should allow to move tokens', () => {
    const toSend = web3.toWei(5, 'ether')

    return crowdsale.transfer(web3.eth.accounts[6], toSend, {
      from: participiants[0].account
    }).then(() => {
      return crowdsale.balanceOf(web3.eth.accounts[6])
    }).then(balance => {
      assert.equal(balance.toString(10), toSend.toString(10))

      return crowdsale.balanceOf(participiants[0].account)
    }).then(balance => {
      assert.equal(participiants[0].balance.minus(toSend).toString(10), balance.toString(10))
    })
  })

  it('Should allow to move vested tokens', () => {
    const vestedAccount = crowdsaleParams.vestingAccounts[0]

    return crowdsale.transfer(web3.eth.accounts[7], vestedAccount.initial, {
      from: vestedAccount.account
    }).then(() => {
      return crowdsale.balanceOf(web3.eth.accounts[7])
    }).then(balance => {
      assert.equal(balance.toString(10), vestedAccount.initial.toString(10))

      return crowdsale.balanceOf(vestedAccount.account)
    }).then(balance => {
      assert.equal(balance.toNumber(), 0)
    })
  })

  it('Should allow to withdraw contractor tokens', () => {
    const toWithdraw = web3.toWei(1, 'ether')
    let multisigBalance

    return crowdsale.multisig.call().then(multisig => {
      multisigBalance = new BigNumber(web3.eth.getBalance(multisig)).add(toWithdraw)
      return crowdsale.withdraw(toWithdraw).then(() => {
        return web3.eth.getBalance(multisig)
      })
    }).then(balance => {
      assert.equal(multisigBalance.toString(10), balance.toString(10))
    })
  })

  it('Shouldnt allow to refund users because crowdsale is success', () => {
    return crowdsale.payback({
      from: web3.eth.accounts[6]
    }).then(() => {
      throw new Error('Shouldnt be here')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should move time to vesting allocation completed and release rest of vesting tokens', () => {
    return time.blockchainTime(web3).then(blockchainTime => {
      const timestamp = timestamps[timestamps.length-1] + 3600
      const seconds = timestamp - blockchainTime

      return time.move(web3, seconds)
    }).then(() => {
      const accounts = crowdsaleParams.vestingAccounts.splice(1)

      return Promise.each(accounts, account => {
        return crowdsale.releaseVestingAllocation({
          from: account.account
        }).then(() => {
          return crowdsale.balanceOf(account.account)
        }).then(balance => {
          assert.equal(balance.toString(10), new BigNumber(account.payment).mul(timestamps.length).add(account.initial).toString(10))
        })
      })
    })
  })

})
