const Promise = require('bluebird')
const Milestones = artifacts.require("../contracts/milestones/BasicMilestones.sol")
const Chance = require('chance')
const crypto = require('crypto')
const parser = require('../helpers/parser')
const errors = require('../helpers/errors')
const time = require('../helpers/time')
const miner = require('../helpers/miner')
const arrayHelper = require('../helpers/arrays')

contract('Milestones', () => {
  let chance = new Chance()
  const creator = web3.eth.accounts[0]
  let milestonesContract
  let currentTime

  let milestones = []

  /*
  .then(_milestones => {
    milestones = _milestones

    const start = currentTime
    const end = start + 3600
    return milestones.setLimitations.sendTransaction(start, end)
  }
  })
*/

  before('Deploy Milestones & Forecasting', () => {
    return time.blockchainTime(web3).then(_time => {
      currentTime = _time
      return Milestones.new(creator, false)
    }).then(milestones => {
      milestonesContract = milestones
    })
  })

  it('Should allow to add five milestones while it is pre-review mode', () => {
    let promises = []

    for (let i = 0; i < 5; i++) {
      const milestone = {
        amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
        items: crypto.randomBytes(32).toString('hex')
      }

      milestones.push(milestone)
      promises.push(milestonesContract.add.sendTransaction(milestone.amount, milestone.items, {
        from: creator
      }))
    }

    return Promise.all(promises)
  })

  it('Should set limitations for milestones', () => {
    const end = currentTime + 3600

    return milestonesContract.setLimitations.sendTransaction(currentTime, end)
  })

  it('Should move time', () => {
    return time.move(web3, 3601).then(() => {
      return time.blockchainTime(web3)
    }).then((time) => {
      return Promise.join(
        milestonesContract.startTimestamp.call(),
        milestonesContract.endTimestamp.call(),
        (start, end) => {
          assert.equal(time > start.toNumber() && time < end.toNumber(), true)
        }
      )
    })
  })

  it('Should add another 5 milestones', () => {
    const promises = []

    for (let i = 0; i < 5; i++) {
      const milestone = {
        amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
        items: crypto.randomBytes(32).toString('hex')
      }

      milestones.push(milestone)
      promises.push(milestonesContract.add.sendTransaction(milestone.amount, milestone.items, {
        from: creator
      }))
    }

    return Promise.all(promises)
  })

  it('Shouldnt allow to add 11th milestone', () => {
    const milestone = {
      amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
      items: crypto.randomBytes(32).toString('hex')
    }

    return milestonesContract.add.sendTransaction(milestone.amount, milestone.items, {
      from: creator
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should contains 10 milestones', () => {
    return milestonesContract.milestonesCount.call(count => {
      assert.equal(count.toNumber(), 10)
    })
  })

  it('Should allow to update milestone', () => {
    const i = chance.integer({min: 0, max: milestones.length - 1})

    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    milestones[i] = newMilestone

    return milestones.update.sendTransaction(i, newMilestone.amount, newMilestone.items, {
      from: creator
    }).then(() => {
      return milestones.get(i)
    }).then(milestoneRawData => {
      const milestoneData = parser.parseMilestone(milestoneRawData)

      assert.equal(milestones[i].amount.toString(10), milestoneData.amount.toString(10))
      assert.equal(milestones[i].items, milestoneData.items)
    })
  })

  it('Should allow to remove milestone', () => {
    const i = 5

    milestones = arrayHelper.remove(milestones, i)
    return milestones.remove(i).then(() => {
      return Promise.each(milestones, (milestone, index) => {
        return milestones.get(index).then(milestoneRawData => {
          const milestoneData = parser.parseMilestone(milestoneRawData)

          assert.equal(milestone.amount.toString(10), milestoneData.amount.toString(10))
          assert.equal(milestone.items, milestoneData.items)
        })
      })
    }).then(() => {
      return milestones.milestonesCount.call()
    }).then(count => {
      assert.equal(count.toString(10), milestones.length.toString(10))
    })
  })

  it('Should contains 9 milestones', () => {
    return milestonesContract.milestonesCount.call(count => {
      assert.equal(count.toNumber(), 9)
    })
  })



})
