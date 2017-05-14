const Wings = artifacts.require('../contracts/Wings.sol')
const Token = artifacts.require('../contracts/Token.sol')

const DAO = artifacts.require('../contracts/DAO.sol')

const CrowdsaleFactory = artifacts.require('./crowdsales/CrowdsaleFactory.sol')
const ForecastingFactory = artifacts.require('./forecasts/ForecastingFactory.sol')
const MilestonesFactory = artifacts.require('./milestones/MilestonesFactory.sol')

const Promise = require('bluebird')
const Chance = require('chance')
const time = require('../helpers/time')
const errors = require('../helpers/errors')
const parser = require('../helpers/parser')
const crypto = require('crypto')

contract('Wings', () => {
  const creator = web3.eth.accounts[0]
  let dao = {}

  let chance = new Chance()
  let token, wings

  before('Deploy Wings To Network', () => {
    dao = {
      owner: creator,
      name: "Wings Awesome DAO",
      symbol: "WINGS",
      infoHash: '0x' + crypto.randomBytes(32).toString('hex'),
      underCap: false,
      reviewHours: chance.integer({min: 1, max: 504 }),
      forecastHours: chance.integer({min: 120, max: 720 }),
      rewardPercent: chance.integer({min: 1, max: 100000000 }),
      crowdsaleHours: chance.integer({min: 168, max: 2016}),
      rewardPercent: chance.integer({min: 1, max: 100000000}),
      initialPrice: 200,
      milestones: [],
      forecasts: []
    }

    return Token.new(1, {
      from: creator
    }).then(_token => {
      token = _token

      return Promise.join(
        MilestonesFactory.new(token.address),
        CrowdsaleFactory.new(token.address),
        ForecastingFactory.new(token.address),
        (milestones, crowdsale, forecasting) => {
          return Wings.new(token.address, milestones.address, crowdsale.address, forecasting.address)
        }
      ).then(_wings => {
        wings = _wings

        return wings.createMilestones(0, dao.underCap, dao.reviewHours, {
          from: creator
        })
      }).then(() => {

        return wings.createCrowdsale(0, creator, dao.name, dao.symbol, dao.initialPrice, dao.rewardPercent, dao.crowdsaleHours, {
          from: creator
        })
      }).then(() => {
        return wings.createForecasting(0, dao.rewardPercent, dao.forecastHours, {
          from: creator
        })
      })
    })
  })

  it('Add DAO project', () => {
    return wings.createDAO(0, dao.name, dao.infoHash, {
      from: creator
    }).then(() => {
      dao.id = '0x' + crypto.createHash('sha256').update(dao.name, 'utf8').digest().toString('hex')
    })
  })

  it('Should contain one project', () => {
    return wings.totalDAOsCount.call().then(count => {
      assert.equal(count.toNumber(), 1)
    })
  })

  it('Should return DAO by id', () => {
    return wings.getDAOById.call(dao.id).then(daoAddress => {
      return DAO.at(daoAddress)
    }).then(dao => {
      return Promise.all([
        dao.owner.call(),
        dao.id.call(),
        dao.infoHash.call()
      ], results => {
        assert.equal(results[0], dao.owner)
        assert.equal(results[1], dao.id)
        assert.equal(results[3], dao.infoHash)
      })
    })
  })

  it('Should get DAO id by index', () => {
    return wings.getDAOId.call(0).then(daoId => {
      assert.equal(daoId, dao.id)
    })
  })

  it('Should return count of my DAOs', () => {
    return wings.getUserDAOsCount.call(creator).then(count => {
      assert.equal(count.toNumber(), 1)
    })
  })

  it('Should return my DAO id by index', () => {
    return wings.getUserDAOsId.call(creator, 0).then(daoId => {
      assert.equal(daoId, dao.id)
    })
  })
})
