const BigNumber = require('bignumber.js')
const Promise = require('bluebird')
const DAO = artifacts.require("../contracts/DAO.sol")
const Token = artifacts.require("../contracts/Token.sol")
const Milestones = artifacts.require("../contracts/milestones/BasicMilestones.sol")
const Forecasting = artifacts.require("../contracts/forecasts/BasicForecasting.sol")
const crypto = require('crypto')
const Chance = require('chance')
const parser = require('../helpers/parser')
const arrayHelper = require('../helpers/arrays')
const errors = require('../helpers/errors')
const time = require('../helpers/time')
const miner = require('../helpers/miner')

contract('DAO', () => {
  const creator = web3.eth.accounts[0]

  let chance = new Chance()
  let dao, daoInfo

  let token, milestones, forecasting

  before('Deploy Wings DAO', () => {
    daoInfo = {
      owner: creator,
      name: "Wings Awesome DAO",
      infoHash: '0x' + crypto.randomBytes(32).toString('hex'),
      category: chance.integer({min: 0, max: 5}),
      underCap: false,
      reviewHours: chance.integer({min: 1, max: 504 }),
      forecastHours: chance.integer({min: 120, max: 720 }),
      rewardPercent: chance.integer({min: 1, max: 100000000 }),
      milestones: [],
      forecasts: []
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
    return dao.start.sendTransaction(daoInfo.forecastHours, daoInfo.rewardPercent, {
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

  it('Should allow to change project data while it is in review mode', () => {
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

  it('Should get forecasting contract', () => {
    return dao.forecasting.call().then(_forecasting => {
      return Forecasting.at(_forecasting)
    }).then(_forecasting => {
      forecasting = _forecasting
    })
  })

  it('Shouldnt allow to add forecast', () => {
    return forecasting.add.sendTransaction(web3.toWei(chance.integer({min: 1, max: 1000 }), 'ether'), '0x' + crypto.randomBytes(32).toString('hex'))
      .catch(err => {
        assert.equal(errors.isJump(err.message), true)
      })
  })

  it('Should move time to forecast period', () => {
    const secondsToMove = (daoInfo.reviewHours * 3600)

    return time.move(web3, secondsToMove).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3).then(blockchainTime => {
        return Promise.join(
          forecasting.startTimestamp.call(),
          forecasting.endTimestamp.call(),
          (start, end) => {
            assert.equal(blockchainTime > start.toNumber() && blockchainTime < end.toNumber(), true)
          })
      })
    })
  })

  it('Should doesnt allow to update DAO', () => {
    const infoHash = '0x' + crypto.randomBytes(32).toString('hex')
    const category = chance.integer({min: 0, max: 5})

    return dao.update.sendTransaction(infoHash, category, {
      from: creator
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should doesnt allow to update milestones', () => {
    const i = chance.integer({min: 0, max: daoInfo.milestones.length - 1})

    const newMilestone = {
      amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
      items: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return milestones.update.sendTransaction(i, newMilestone.amount, newMilestone.items, {
      from: creator
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should add forecast', () => {
    const forecast = {
      address: web3.eth.accounts[1],
      amount: web3.toWei(chance.integer({min: 1, max: 1000 }), 'ether'),
      message: '0x' + crypto.randomBytes(32).toString('hex')
    }

    daoInfo.forecasts.push(forecast)

    return forecasting.add.sendTransaction(forecast.amount, forecast.message, {
      from: forecast.address
    })
  })

  it('Should contains one forecast', () => {
    return forecasting.forecastsCount.call().then(count => {
      assert.equal(count.toString('10'), 1)
    })
  })

  it('Should return one forecast object', () => {
    return forecasting.get.call(0).then(forecastRawData => {
      const forecast = parser.parseForecast(forecastRawData)

      assert.equal(daoInfo.forecasts[0].address, forecast.creator)
      assert.equal(daoInfo.forecasts[0].amount.toString('10'), forecast.amount.toString('10'))
      assert.equal(daoInfo.forecasts[0].message, forecast.message)
    })
  })

  it('Should return user forecast', () => {
    return forecasting.getByUser.call(daoInfo.forecasts[0].address).then((forecastRawData) => {
      const forecast = parser.parseUserForecast(forecastRawData)

      assert.equal(daoInfo.forecasts[0].amount.toString('10'), forecast.amount.toString('10'))
      assert.equal(daoInfo.forecasts[0].message, forecast.message)
    })
  })

  it('Should complete forecast period', () => {
    const secondsToMove = (daoInfo.forecastHours * 3600)

    return time.move(web3, secondsToMove).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return time.blockchainTime(web3).then(blockchainTime => {
        return Promise.join(
          forecasting.startTimestamp.call(),
          forecasting.endTimestamp.call(),
          (start, end) => {
            assert.equal(blockchainTime > end.toNumber(), true)
          })
      })
    })
  })

  it('Should does not allow to add new forecast', () => {
    return forecasting.add.sendTransaction(
      web3.toWei(chance.integer({min: 1, max: 1000 }), 'ether'),
      '0x' + crypto.randomBytes(32).toString('hex'), {
        from: web3.eth.accounts[3]
      }).catch(err => {
        assert.equal(errors.isJump(err.message), true)
      })
  })

})
