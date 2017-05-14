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
      name: chance.word(),
      symbol: chance.word(),
      infoHash: '0x' + crypto.randomBytes(32).toString('hex'),
      underCap: false,
      reviewHours: chance.integer({min: 1, max: 504 })
    }

    return Token.new(1, {
      from: creator
    }).then(_token => {
      token = _token

      return Promise.join(
        CrowdsaleFactory.new(),
        ForecastingFactory.new(),
        MilestonesFactory.new(),
        (crowdsale, forecasting, milestones) => {
          return Wings.new(token.address, milestones.address, crowdsale.address, forecasting.address)
        }
      ).then(_wings => {
        wings = _wings
      })
    })
  })

  it('Add DAO project', () => {
    return wings.addDAO.sendTransaction(dao.name, dao.symbol, dao.infoHash, dao.underCap, dao.reviewHours, {
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
        dao.name.call(),
        dao.infoHash.call(),
        dao.token.call(),
        dao.reviewHours.call()
      ], results => {
        assert.equal(results[0], dao.owner)
        assert.equal(results[1], dao.id)
        assert.equal(results[2], dao.name)
        assert.equal(results[3], dao.infoHash),
        assert.equal(results[4], token.address),
        assert.equal(results[5].toNumber(), dao.reviewHours)
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
