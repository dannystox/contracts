const Promise = require('bluebird')
const Forecasting = artifacts.require("../contracts/forecasts/BasicForecasting.sol")
const Milestones = artifacts.require("../contracts/milestones/BasicMilestones.sol")
const Crowdsale = artifacts.require("../contracts/crowdsales/BasicCrowdsale.sol")
const Token = artifacts.require("../contracts/Token.sol")
const Chance = require('chance')
const crypto = require('crypto')
const parser = require('../helpers/parser')
const errors = require('../helpers/errors')
const time = require('../helpers/time')
const miner = require('../helpers/miner')

contract('Forecasting Alone', () => {
  let chance = new Chance()
  const creator = web3.eth.accounts[0]
  let forecasting, milestones, token, crowdsale
  let currentTime

  before('Deploy Milestones & Forecasting', () => {
    return time.blockchainTime(web3).then(_time => {
      currentTime = _time
      return Milestones.new(creator, false)
    }).then(_milestones => {
      milestones = _milestones

      const start = currentTime
      const end = start + 3600
      return milestones.setLimitations.sendTransaction(start, end)
    }).then(() => {
      return Token.new(1)
    }).then(_token => {
      token = _token
      return Crowdsale.new(
          creator,
          creator,
          creator,
          chance.word(),
          chance.word(),
          milestones.address,
          chance.integer({min: 1, max: 500}),
          chance.integer({min: 1, max: 1000})
        )
    }).then(_crowdsale => {
      crowdsale = _crowdsale

      const start = currentTime + 3600
      const end = start + 3600

      const rewardPercent = chance.integer({min: 1, max: 100000000 })

      return Forecasting.new(start, end, rewardPercent, token.address, milestones.address, crowdsale.address, false)
    }).then(_forecasting => {
      forecasting = _forecasting
    })
  })

  it('Shouldnt allow to add forecast now', () => {
      const forecast = {
        address: web3.eth.accounts[1],
        amount: web3.toWei(chance.integer({min: 1, max: 1000 }), 'ether'),
        message: '0x' + crypto.randomBytes(32).toString('hex')
      }

      return forecasting.add.sendTransaction(forecast.amount, forecast.message).catch(err => {
        assert.equal(errors.isJump(err.message), true)
      })
  })

  it('Should allow to move time', () => {
    return time.move(web3, 3601).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return Promise.join(
        forecasting.startTimestamp.call(),
        forecasting.endTimestamp.call()
      , (start, end) => {
        const block = web3.eth.getBlock(web3.eth.blockNumber)

        assert.equal(block.timestamp > start.toNumber() && block.timestamp < end.toNumber(), true)
      })
    })
  })

  it('Should allow to add forecast', () => {
    const forecast = {
      address: web3.eth.accounts[1],
      amount: web3.toWei(chance.integer({min: 1, max: 1000 }), 'ether'),
      message: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return forecasting
      .add
      .sendTransaction(forecast.amount, forecast.message)
  })

  it('Should contain at least one forecast', () => {
    return forecasting.forecastsCount.call().then(_count => {
      assert.equal(_count.toNumber(10), 1)
    })
  })

  it('Should move time after forecast', () => {
    return time.move(web3, 3601).then(() => {
      return miner.mine(web3)
    }).then(() => {
      return Promise.join(
        forecasting.startTimestamp.call(),
        forecasting.endTimestamp.call()
      , (start, end) => {
        const block = web3.eth.getBlock(web3.eth.blockNumber)

        assert.equal(block.timestamp > end.toNumber(), true)
      })
    })
  })

  it('Shouldnt allow to add forecast after time of forecasting closed', () => {
    const forecast = {
      address: web3.eth.accounts[1],
      amount: web3.toWei(chance.integer({min: 1, max: 1000 }), 'ether'),
      message: '0x' + crypto.randomBytes(32).toString('hex')
    }

    return forecasting
      .add
      .sendTransaction(forecast.amount, forecast.message)
      .catch(err => {
        assert.equal(errors.isJump(err.message), true)
      })
  })

  it('Should still contains one forecast', () => {
    return forecasting.forecastsCount.call().then(count => {
      return assert.equal(count.toString(10), '1')
    })
  })


})
