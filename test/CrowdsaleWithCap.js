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

contract('CrowdsaleWithCap', () => {
  const creator = web3.eth.accounts[0]
  let chance = new Chance()

  let milestones, forecasting, crowdsale
  let startTime, rewardPercet

  let multisig

  let milestonesItems = []
  let participiants = []
  let crowdsaleParams = {}
  let vestingAccounts = []
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

      return Milestones.new(creator, true)
    }).then(_milestones => {
      milestones = _milestones

      // add milestones and set limittation to two hours ago
      for (let i = 0; i < 4; i++) {
        const milestone = {
          amount: web3.toWei(1, 'ether'),
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
        true
      )
    }).then(_forecasting => {
      forecasting = _forecasting
      multisig = web3.eth.accounts[1]

      return Crowdsale.new(
        creator,
        multisig,
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

  it('Should allow to add vesting account now', () => {
    vestingAccounts = []

    for (let i = 2; i <= 3; i++) {
      vestingAccounts.push({
        account: web3.eth.accounts[i],
        initial: web3.toWei(100, 'ether'),
        payment: web3.toWei(50, 'ether')
      })
    }

    return Promise.each(vestingAccounts, vestingAccount => {
      return crowdsale.addVestingAccount(vestingAccount.account, vestingAccount.initial, vestingAccount.payment).then(() => {
        return Promise.each(timestamps, timestamp => {
          return crowdsale.addVestingAllocation(vestingAccount.account, timestamp)
        })
      })
    })
  })

  it('Should contains vesting accounts', () => {
    return Promise.each(vestingAccounts, vestingAccount => {
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

  it('Should move time to crowdsale available for participiants', () => {
    return time.move(web3, 7200).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3)
    }).then(blockchainTime => {
      assert.equal(crowdsaleStartTime <= blockchainTime, true)
    })
  })

  it('Should allow to send ETH in exchange of Tokens', () => {
    participiants = web3.eth.accounts.slice(4, 8).map(account => {
      return {
        account: account,
        sent: web3.toWei(1, 'ether')
      }
    })

    const currentParticipiants = participiants.slice(0, 3)

    return Promise.each(currentParticipiants, participiant => {
      return new Promise((resolve, reject) => {
        web3.eth.sendTransaction({
          from: participiant.account,
          to: crowdsale.address,
          value: participiant.sent,
          gas: 130000
        }, (err) => {
          err? reject(err) : resolve()
        })
      })
    })
  })

  it('Participiants balances should be updated', () => {
    return crowdsale.getPrice.call().then(price => {
      const currentParticipiants = participiants.slice(0, 3)

      return Promise.each(currentParticipiants, participiant => {
        return crowdsale.balanceOf.call(participiant.account).then(balance => {
          assert.equal(balance.toString(10), new BigNumber(participiant.sent).mul(price).toString(10))
        })
      })

    })
  })

  it('Shouldnt allow to send more then cap', () => {
    const participiant = participiants[participiants.length-1]

    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: participiant.account,
        to: crowdsale.address,
        value: web3.toWei(2, 'ether'),
        gas: 130000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      throw new Error('Should send JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Crowdsale balance should be less then cap', () => {
    return crowdsale.totalCollected.call().then(totalCollected => {
      return milestones.totalAmount.call().then(totalAmount => {
        assert.equal(totalAmount.gt(totalCollected), true)
      })
    })
  })


  it('Shouldnt possible to move tokens while crowdsale alive', () => {
    const recipient = web3.eth.accounts[9]
    const participiant = participiants[0]
    let initialBalance

    return crowdsale.balanceOf.call(participiant.account).then(balance => {
      initialBalance = balance

      return crowdsale.transfer(recipient, balance, {
        from: participiant.account
      })
    }).then(() => {
      throw new Error('Should return JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.balanceOf(participiant.account)
    }).then(balance => {
      assert.equal(balance.toString(10), initialBalance.toString(10))
    })
  })


  it('Should complete crowdsale with latest transaction that cover cap', () => {
    const participiant = participiants[participiants.length-1]

    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: participiant.account,
        to: crowdsale.address,
        value: participiant.sent,
        gas: 130000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      return crowdsale.balanceOf.call(participiant.account)
    }).then(balance => {
      return crowdsale.getPrice.call().then(price => {
        assert.equal(balance.toString(10), new BigNumber(participiant.sent).mul(price).toString(10))
      })
    })
  })

  it('Crowdsale balance should equal cap', () => {
    return crowdsale.totalCollected.call().then(totalCollected => {
      return milestones.totalAmount.call().then(totalAmount => {
        assert.equal(totalCollected.toString(10), totalAmount.toString(10))
      })
    })
  })

  it('Should complete crowdsale because cap reached', () => {
    const participiant = {
      account: web3.eth.accounts[9],
      sent: web3.toWei(1, 'ether')
    }

    return new Promise((resolve, reject) => {
      web3.eth.sendTransaction({
        from: participiant.account,
        to: crowdsale.address,
        value: participiant.sent,
        gas: 130000
      }, (err) => {
        err? reject(err) : resolve()
      })
    }).then(() => {
      throw new Error('Should send JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Time should be still under crowdsale end', () => {
    return time.blockchainTime(web3).then(blockchainTime => {
      assert.equal(blockchainTime < crowdsaleEndTime, true)
    })
  })


  it('Should allow to move tokens', () => {
    const participiant = participiants[0]
    const recipient = web3.eth.accounts[9]

    let initialBalance

    return crowdsale.balanceOf.call(participiant.account).then(balance => {
      initialBalance = balance

      return crowdsale.transfer(recipient, balance, {
        from: participiant.account
      })
    }).then(() => {
      return crowdsale.balanceOf(participiant.account)
    }).then(balance => {
      assert.equal(balance.toNumber(), 0)

      return crowdsale.balanceOf(recipient)
    }).then(balance => {
      assert.equal(balance.toString(10), initialBalance.toString(10))
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
      const accounts = vestingAccounts.splice(1)

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
