const BigNumber = require('bignumber.js')
const Promise = require('bluebird')
const DAO = artifacts.require("../contracts/DAO.sol")
const Token = artifacts.require("../contracts/Token.sol")
const Milestones = artifacts.require("../contracts/milestones/BasicMilestones.sol")
const crypto = require('crypto')
const Chance = require('chance')
const parser = require('../helpers/parser')
const arrayHelper = require('../helpers/arrays')
const errors = require('../helpers/errors')
const time = require('../helpers/time')

contract('DAO', () => {
  const creator = web3.eth.accounts[0]

  let chance = new Chance()
  let dao, daoInfo

  let token, milestones

  before('Deploy Wings DAO', () => {
    daoInfo = {
      owner: creator,
      name: "Wings Awesome DAO",
      infoHash: '0x' + crypto.randomBytes(32).toString('hex'),
      category: chance.integer({min: 0, max: 5}),
      underCap: false,
      reviewHours: chance.integer({min: 1, max: 504 }),
      forecastHours: chance.integer({min: 120, max: 720 }),
      milestones: []
    }



    for (let i = 0; i < 10; i++) {
      const milestone = {
        amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
        items: '0x' + crypto.randomBytes(32).toString('hex')
      }

      daoInfo.milestones.push(milestone)
    }

    return Token.new(web3.eth.accounts.length, {
      from: creator
    }).then(_token => {
      token = _token

      return DAO.new(daoInfo.owner, daoInfo.name, daoInfo.infoHash, daoInfo.category, daoInfo.underCap, daoInfo.reviewHours, token.address,  {
        from: creator
      })
    }).then(_dao => {
      dao = _dao
      return dao.owner.call()
    }).then(owner => {
      assert.equal(owner, creator)
    })
  })


  it('Should create & set forecast contract', () => {
    return dao.enableForecasts.sendTransaction(daoInfo.forecastHours, {
      from: creator
    })
  })

  it('Should allow to update DAO info before start', () => {
    daoInfo.infoHash = '0x' + crypto.randomBytes(32).toString('hex')
    daoInfo.category = chance.integer({min: 0, max: 5})

    return dao.update.sendTransaction(daoInfo.infoHash, daoInfo.category, {
      from: creator
    }).then(() => {
      return dao.infoHash.call()
    }).then(infoHash => {
      assert.equal(infoHash, daoInfo.infoHash)
      return dao.category.call()
    }).then(category => {
      assert.equal(category, daoInfo.category)
    })
  })

  it('Should allow to get milestones contract', () => {
    return dao.milestones.call().then(address => {
      return Milestones.at(address)
    }).then(_milestones => {
      milestones = _milestones
    })
  })

  it('Should allow to add milestone', () => {
    return Promise.each(daoInfo.milestones, (milestone) => {
      return milestones.add.sendTransaction(milestone.amount, milestone.items, {
        from: creator
      })
    }).then(() => {
      return Promise.each(daoInfo.milestones, (milestone, index) => {
        return milestones.get.call(index).then(milestoneRawData => {
          const milestoneData = parser.parseMilestone(milestoneRawData)

          assert.equal(milestone.amount.toString(10), milestoneData.amount.toString(10))
          assert.equal(milestone.items, milestoneData.items)
        })
      })
    }).then(() => {
      return milestones.milestonesCount.call()
    }).then(milestonesCount => {
      assert.equal(milestonesCount.toString(10), daoInfo.milestones.length)
    })
  })

  it('Should allow to update milestone', () => {
    const i = chance.integer({min: 0, max: daoInfo.milestones.length - 1})

    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    daoInfo.milestones[i] = newMilestone

    return milestones.update.sendTransaction(i, newMilestone.amount, newMilestone.items, {
      from: creator
    }).then(() => {
      return milestones.get(i)
    }).then(milestoneRawData => {
      const milestoneData = parser.parseMilestone(milestoneRawData)

      assert.equal(daoInfo.milestones[i].amount.toString(10), milestoneData.amount.toString(10))
      assert.equal(daoInfo.milestones[i].items, milestoneData.items)
    })
  })

  it('Should doesnt allow to add more then 10 milestones', () => {
    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return milestones.add(newMilestone.amount, newMilestone.items).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should allow to remove milestone', () => {
    const i = 5

    daoInfo.milestones = arrayHelper.remove(daoInfo.milestones, i)

    return milestones.remove(i).then(() => {
      return Promise.each(daoInfo.milestones, (milestone, index) => {
        return milestones.get(index).then(milestoneRawData => {
          const milestoneData = parser.parseMilestone(milestoneRawData)

          assert.equal(milestone.amount.toString(10), milestoneData.amount.toString(10))
          assert.equal(milestone.items, milestoneData.items)
        })
      })
    }).then(() => {
      return milestones.milestonesCount.call()
    }).then(count => {
      assert.equal(count.toString(10), daoInfo.milestones.length.toString(10))
    })
  })

  it('Should allow to start DAO', () => {
    return dao.start.sendTransaction({
      from: creator
    })
  })

  it('Should allow to add new milestone after DAO started in review mode', () => {
    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    daoInfo.milestones.push(newMilestone)

    return milestones.add(newMilestone.amount, newMilestone.items)
      .then(() => {
        return Promise.each(daoInfo.milestones, (milestone, index) => {
          return milestones.get(index).then(milestoneRawData => {
            const milestoneData = parser.parseMilestone(milestoneRawData)

            assert.equal(milestone.amount.toString(10), milestoneData.amount.toString(10))
            assert.equal(milestone.items, milestoneData.items)
          })
        })
      })
  })

  it('Should allow to update milestone after DAO started', () => {
    const i = chance.integer({min: 0, max: daoInfo.milestones.length - 1})

    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    daoInfo.milestones[i] = newMilestone

    return milestones.update.sendTransaction(i, newMilestone.amount, newMilestone.items, {
      from: creator
    }).then(() => {
      return milestones.get(i)
    }).then(milestoneRawData => {
      const milestoneData = parser.parseMilestone(milestoneRawData)

      assert.equal(daoInfo.milestones[i].amount.toString(10), milestoneData.amount.toString(10))
      assert.equal(daoInfo.milestones[i].items, milestoneData.items)
    })
  })

  it('Should allow to remove milestones after DAO started', () => {
    const i = 5

    daoInfo.milestones = arrayHelper.remove(daoInfo.milestones, i)

    return milestones.remove(i).then(() => {
      return Promise.each(daoInfo.milestones, (milestone, index) => {
        return milestones.get(index).then(milestoneRawData => {
          const milestoneData = parser.parseMilestone(milestoneRawData)

          assert.equal(milestone.amount.toString(10), milestoneData.amount.toString(10))
          assert.equal(milestone.items, milestoneData.items)
        })
      })
    }).then(() => {
      return milestones.milestonesCount.call()
    }).then(count => {
      assert.equal(count.toString(10), daoInfo.milestones.length.toString(10))
    })
  })

  it.skip('Should move time to forecast period', () => {
    const secondsToMove = (daoInfo.reviewHours * 3600) + 1

    return time.move(web3, secondsToMove)
  })

  it('Should doesnt allow  update to modificate, or update, or remove milestone', () => {
    const i = 5
    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return milestones.remove(5).catch(err => {
      assert.equal(errors.isJump(err.message), true)

      return milestones.update(5, newMilestone.amount, newMilestone.items)
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
      return milestones.add(newMilestone.amount, newMilestone.items)
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it.skip('Should allow to add forecast', () => {

  })

})
