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

contract('CrowdsaleFailed', () => {
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
    rewardPercent = chance.integer({min: 1, max: 100000000 })

    now.setHours(1,0,0,0)

    for (let i = 0; i < vestingMonthes; i++) {
      now.setMonth(now.getMonth() + 1, 1)

      timestamps.push(time.toSeconds(now.getTime()))
    }

    return time.blockchainTime(web3).then(time => {
      startTime = time

      return Milestones.new(creator, creator, false)
    }).then(_milestones => {
      milestones = _milestones

      const milestoneStartTime = startTime
      const milestoneEndTime = startTime + 3600

      return milestones.setTime(milestoneStartTime, milestoneEndTime, {
        from: creator
      })
    }).then(() => {
      milestonesItems.push({
        amount: web3.toWei(100, 'ether'),
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
        return milestones.add(milestone.amount, milestone.items, {
          from: creator
        })
      })
    }).then(() => {
      multisig = web3.eth.accounts[1]

      return Crowdsale.new(
        creator,
        creator,
        multisig,
        "Wings",
        "WINGS",
        milestones.address,
        10,
        rewardPercent
      )
    }).then(_crowdsale => {
      crowdsale = _crowdsale

      const forecastingStartTime = startTime + 3600
      const forecastingEndTime = startTime + 7200

      return Forecasting.new(
        creator,
        rewardPercent,
        '0x0',
        milestones.address,
        crowdsale.address
      ).then(forecasting => {
        return forecasting.setTime(forecastingStartTime, forecastingEndTime).then(() => forecasting)
      })
    }).then(_forecasting => {
      forecasting = _forecasting

      return crowdsale.setForecasting(forecasting.address)
    })
  })

  it('Should allow to add vesting account now', () => {
    vestingAccounts = []

    for (let i = 2; i <= 4; i++) {
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
    participiants = web3.eth.accounts.splice(5, 8).map(account => {
      return {
        account: account,
        sent: web3.toWei(1, 'ether')
      }
    })

    return Promise.each(participiants, participiant => {
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

      return Promise.each(participiants, participiant => {
        return crowdsale.balanceOf.call(participiant.account).then(balance => {
          assert.equal(balance.toString(10), new BigNumber(participiant.sent).mul(price).toString(10))
        })
      })

    })
  })

  it('Crowdsale balance should be still under cap', () => {
    return crowdsale.totalCollected.call().then(totalCollected => {
      assert.equal(totalCollected.lt(milestonesItems[0].amount), true)
    })
  })

  it('Should move time to end of crowdsale participiants period', () => {
    return time.move(web3, 3600).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3)
    }).then(blockchainTime => {
      assert.equal(blockchainTime >= crowdsaleEndTime, true)
    })
  })

  it('Crowdsale should be failed and doesnt allow to send tokens', () => {
    let initialBalance, recipientBalance
    const recipient = web3.eth.accounts[9]

    return crowdsale.balanceOf(recipient).then(_recipientBalance => {
      recipientBalance = _recipientBalance

      return crowdsale.balanceOf(participiants[0].account).then(balance => {
        initialBalance = balance

        return crowdsale.transfer(recipient, balance, {
          from: participiants[0].account
        })
      })
    }).then(() => {
      throw new Error('Should return JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    }).then(() => {
      return crowdsale.balanceOf(participiants[0].account).then(balance => {
        assert.equal(balance.toString(10), initialBalance.toString(10))

        return crowdsale.balanceOf.call(recipient)
      })
    }).then(balance => {
      assert.equal(balance.toNumber(), recipientBalance)
    })
  })

  it('Shouldnt allow to withdraw collected eth', () => {
    const multisigBalance = web3.eth.getBalance(multisig)

    return crowdsale.totalCollected.call().then(totalCollected => {
      return crowdsale.withdraw(totalCollected, {
        from: web3.eth.accounts[0]
      })
    }).then(() => {
      throw new Error('Should return JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)

      return web3.eth.getBalance(multisig)
    }).then(balance => {
      assert.equal(multisigBalance.toString(10), balance.toString(10))
    })
  })

  it('Shouldnt allow to send vested tokens', () => {
    let initialBalance
    const recipient = web3.eth.accounts[9]

    return Promise.each(vestingAccounts, vestedAccount => {
      return crowdsale.balanceOf(vestedAccount.account).then(balance => {
        initialBalance = balance
        return crowdsale.transfer(recipient, balance)
      }).then(() => {
        throw new Error('Should return JUMP error')
      }).catch(err => {
        assert.equal(errors.isJump(err.message), true)
      }).then(() => {
        return crowdsale.balanceOf(vestedAccount.account)
      }).then(balance => {
        assert.equal(balance.toString(10), initialBalance.toString(10))
      })
    })
  })

  it('Should allow to get backed ETH back', () => {
    return Promise.each(participiants, participiant => {
      const ethBalance = web3.eth.getBalance(participiant.account)

      return crowdsale.payback({
        from: participiant.account
      }).then(result => {
        const newEthBalance = web3.eth.getBalance(participiant.account)
        const different = newEthBalance.minus(ethBalance)

        assert.equal(newEthBalance.gt(ethBalance), true)
        assert.equal(different.gt(web3.toWei(0.95, 'ether')), true)
      })
    })
  })

  it('Shouldnt allow to release vested tokens', () => {
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
          throw new Error('Should return JUMP error')
        }).catch(err => {
          assert.equal(errors.isJump(err.message), true)
        }).then(() => {
          return crowdsale.balanceOf(account.account)
        }).then(balance => {
          assert.equal(balance.toString(10), account.initial.toString(10))
        })
      })
    })
  })

})
