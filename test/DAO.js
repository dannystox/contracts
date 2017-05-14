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

  before('Deploy Wings DAO', () => {
    daoInfo = {
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

    for (let i = 0; i < 10; i++) {
      const milestone = {
        amount: web3.toWei(chance.integer({min: 10, max: 1000}), 'ether'),
        items: '0x' + crypto.randomBytes(32).toString('hex')
      }

      daoInfo.milestones.push(milestone)
    }

    let currentTime, startTime, endTime

    return time.blockchainTime(web3).then(_time => {
      currentTime = _time

      return Token.new(web3.eth.accounts.length, {
        from: creator
      })
    }).then(_token => {
      token = _token

      return DAO.new(
          creator,
          creator,
          crypto.createHash('sha256').update(daoInfo.name, 'utf8').digest().toString('hex'),
          daoInfo.infoHash,
          '0x0',
          '0x0',
          '0x0',
          {
            from: creator
          })
    }).then(_dao => {
      dao = _dao
      return dao.owner.call()
    }).then(owner => {
      assert.equal(owner, creator)

      startTime = currentTime
      endTime = startTime+3600
      return dao.setTime(startTime, endTime, {
        from: creator
      })
    })
  })

  it('Should allow to update DAO info', () => {
    daoInfo.infoHash = '0x' + crypto.randomBytes(32).toString('hex')

    return dao.update(daoInfo.infoHash, {
      from: creator
    }).then(() => {
      return dao.infoHash.call()
    }).then(infoHash => {
      assert.equal(infoHash, daoInfo.infoHash)
    })
  })

  it('Should move time after review period', () => {
    return time.blockchainTime(web3).then(currentTime => {
      return time.move(web3, currentTime+3601)
    }).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return Promise.join(
        time.blockchainTime(web3),
        dao.endTimestamp.call(),
        (currentTime, endTimestamp) => {
          assert.equal(endTimestamp.lt(currentTime), true)
        }
      )
    })
  })

  it('Shouldnt possible to change info hash', () => {
    const infoHash = '0x' + crypto.randomBytes(32).toString('hex')

    return dao.update(infoHash, {
      from: creator
    }).then(() => {
      throw new Error('Should return JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

})
