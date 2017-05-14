const Promise = require('bluebird')
const Milestones = artifacts.require("../contracts/milestones/BasicMilestones.sol")
const Chance = require('chance')
const crypto = require('crypto')
const parser = require('../helpers/parser')
const errors = require('../helpers/errors')
const time = require('../helpers/time')
const miner = require('../helpers/miner')
const BigNumber = require('bignumber.js')
const arrayHelper = require('../helpers/arrays')

contract('Milestones', () => {
  let chance = new Chance()
  const creator = web3.eth.accounts[0]
  let milestonesContract
  let currentTime

  let milestones = []

  before('Deploy Milestones & Forecasting', () => {
    return time.blockchainTime(web3).then(_time => {
      currentTime = _time
      return Milestones.new(creator, creator, false)
    }).then(milestones => {
      milestonesContract = milestones
    })
  })

  it('Shouldnt allow to add milestones before timestamps set', () => {
    const milestone = {
      amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return milestonesContract.add(milestone.amount, milestone.items, {
      from: creator
    }).then(() => {
      throw new Error('Should return JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })


  it('Should set timestamps', () => {
    const end = currentTime + 3600

    return milestonesContract.setTime(currentTime, end, {
      from: creator
    })
  })

  it("Should add 5 milestones", () => {
    let promises = []

    for (let i = 0; i < 5; i++) {
      const milestone = {
        amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
        items: '0x' + crypto.randomBytes(32).toString('hex')
      }

      milestones.push(milestone)
    }

    return Promise.each(milestones, milestone => {
      return milestonesContract.add.sendTransaction(milestone.amount, milestone.items, {
        from: creator
      })
    })
  })

  it('Should contains 5 milestones', () => {
    return milestonesContract.milestonesCount.call().then(count => {
      assert.equal(count.toNumber(), milestones.length)
    })
  })

  it('Should contains right 5 milestones', () => {
    return Promise.each(milestones, (milestone, index) => {
      return milestonesContract.get.call(index).then((rawMilestoneData) => {
        const parsedMilestone = parser.parseMilestone(rawMilestoneData)

        assert.equal(milestone.amount.toString(10), parsedMilestone.amount.toString(10))
        assert.equal(milestone.items, parsedMilestone.items)
      })
    })
  })

  it('Should contains right total amount', () => {
    let totalAmount = new BigNumber(0)

    return Promise.each(milestones, milestone => {
      totalAmount = totalAmount.add(milestone.amount)
    }).then(() => {
      return milestonesContract.totalAmount.call()
    }).then(amount => {
      return assert.equal(amount.toString(10), totalAmount.toString(10))
    })
  })


  it('Should check timestamps', () => {
    return time.blockchainTime(web3).then((time) => {
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
        items: '0x' + crypto.randomBytes(32).toString('hex')
      }

      milestones.push(milestone)
    }

    const milestonesToPublish = milestones.slice(5)
    return Promise.each(milestonesToPublish, milestone => {
      return milestonesContract.add.sendTransaction(milestone.amount, milestone.items, {
        from: creator
      })
    })
  })

  it('Shouldnt allow to add 11th milestone', () => {
    const milestone = {
      amount: web3.toWei(chance.integer({min: 1, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
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

  it('Should allow to update milestone: ', () => {
    const i = chance.integer({min: 0, max: milestones.length - 1})

    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    milestones[i] = newMilestone

    return milestonesContract.update.sendTransaction(i, newMilestone.amount, newMilestone.items, {
      from: creator
    }).then(() => {
      return milestonesContract.get(i)
    }).then(milestoneRawData => {
      const milestoneData = parser.parseMilestone(milestoneRawData)

      assert.equal(milestones[i].amount.toString(10), milestoneData.amount.toString(10))
      assert.equal(milestones[i].items, milestoneData.items)
    })
  })

  it('Should allow to remove milestone', () => {
    const i = 5

    milestones = arrayHelper.remove(milestones, i)
    return milestonesContract.remove(i).then(() => {
      return Promise.each(milestones, (milestone, index) => {
        return milestonesContract.get.call(index).then(milestoneRawData => {
          const milestoneData = parser.parseMilestone(milestoneRawData)

          assert.equal(milestone.amount.toString(10), milestoneData.amount.toString(10))
          assert.equal(milestone.items, milestoneData.items)
        })
      })
    }).then(() => {
      return milestonesContract.milestonesCount.call()
    }).then(count => {
      assert.equal(count.toString(10), milestones.length.toString(10))
    })
  })

  it('Should contains 9 milestones', () => {
    return milestonesContract.milestonesCount.call(count => {
      assert.equal(count.toNumber(), 9)
    })
  })

  it('Should move time to non-modificate period', () => {
      return time.move(web3, 3600).then(() => {
        return miner.mine(web3)
      }).then(() => {
        return time.blockchainTime(web3)
      }).then((time) => {
        return milestonesContract.endTimestamp.call().then(end => {
          assert.equal(time > end.toNumber(), true)
        })
      })
  })

  it('Should doesnt allow to add/update/remove new milestones', () => {
    const i = 5

    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return milestonesContract.remove(i).catch(err => {
      assert.equal(errors.isJump(err.message), true)

      return milestonesContract.update(i, newMilestone.amount, newMilestone.items)
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)

      return milestonesContract.add(newMilestone.amount, newMilestone.items)
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

})
