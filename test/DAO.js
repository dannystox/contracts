const BigNumber = require('bignumber.js')
const Promise = require('bluebird')
const DAO = artifacts.require("../contracts/DAO.sol")
const crypto = require('crypto')
const Chance = require('chance')

contract('DAO', () => {
  const creator = web3.eth.accounts[0]

  let chance = new Chance()
  let dao, daoInfo

  before('Deploy Wings DAO', () => {
    daoInfo = {
      owner: creator,
      name: "Wings Awesome DAO",
      infoHash: '0x' + crypto.randomBytes(32).toString('hex'),
      category: chance.integer({min: 0, max: 5}),
      underCap: false,
      reviewHours: chance.integer({min: 1, max: 36 }),
      forecastHours: chance.integer({min: 1, max: 730 })
    }

    console.log(daoInfo)

    return DAO.new(daoInfo.owner, daoInfo.name, daoInfo.infoHash, daoInfo.category, daoInfo.underCap,  {
      from: creator
    }).then(_dao => {
      dao = _dao
    }).then(() => {
      return dao.owner.call()
    }).then(owner => {
      assert.equal(owner, creator)
    })
  })

  it('Should set review hours', () => {
    return dao.setReviewHours.sendTransaction(daoInfo.reviewHours, {
      from: creator
    })
  })

  it('Should set forecast hours', () => {
    return dao.setForecastHours.sendTransaction(daoInfo.forecastHours, {
      from: creator
    })
  })

  it('Should create & set forecast contract', () => {
    return dao.enableForecasts.sendTransaction({
      from: creator
    })
  })

  it('Should create & set milestones contract', () => {
    return dao.enableMilestones.sendTransaction({
      from: creator
    })
  })

  it('Should allow to start DAO', () => {
    return dao.start.sendTransaction({
      from: creator
    })
  })

  it('Should allow to update DAO info', () => {
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

  it.skip('Should allow to add milestone', () => {

  })

  it.skip('Should allow to update milestone', () => {

  })

  it.skip('Should allow to remove milestone', () => {

  })

  it.skip('Should move time to forecast period', () => {

  })

  it.skip('Should allow to add forecast', () => {

  })

})
