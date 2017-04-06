const BigNumber = require('bignumber.js')
const Promise = require('bluebird')
const Token = artifacts.require("../contracts/Token.sol")
const premine = require('./resources/premine.json')
const time = require('../helpers/time')
const errors = require('../helpers/errors')
const parser = require('../helpers/parser')

contract('Token/Premine', () => {
  const creator = web3.eth.accounts[0]
  const toSend = web3.toWei(100, 'ether')
  const preminer = {
    "address": "0x8f9318230e6c4d416a0ad9bb9ce105bb74170b93",
    "balance": "1031666670000000000000000",
    "payment": "104166660000000000000000",
    "duration": 26
  }

  const oneAcc = '0x8f9318230e6c4d416a0ad9bb9ce105bb74170c93'

  let preminers = []

  const duration = 26

  let token
  const timestamps = []

  before('Deploy Wings Token', () => {
    assert.notEqual(preminer.length, 0)

    let now = new Date()
    now.setHours(1,0,0,0)

    for (let i = 0; i < duration; i++) {
      now.setMonth(now.getMonth() + 1, 1)

      timestamps.push(time.toSeconds(now.getTime()))
    }

    preminers = [{
      "address": web3.eth.accounts[0],
      "balance": premine.balance,
      "payment": premine.payment,
      "total": premine.total
    }]

    return Token.new(preminers.length+1, {
      from: creator
    }).then(_token => {
      token = _token
    }).then(() => {
      return token.owner.call()
    }).then(owner => {
      assert.equal(owner, creator)
    })
  })

  it('Allocation should be equal \'true\'', () => {
    return token.accountsToAllocate.call().then((allocation) => {
      assert.equal(allocation.toNumber(), preminers.length+1)
    })
  })


  it('Should add preminer to preminers list and allocate initial balance', () => {
    return Promise.each(preminers, (preminer) => {
      return token.addPreminer.sendTransaction(preminer.address, preminer.balance, preminer.payment, {
        from: creator
      })
    }).then((txId) => {
      return Promise.each(preminers, (preminer) => {
        return token.balanceOf.call(preminer.address).then(balance => {
          assert.equal(balance.toString(10), preminer.balance)
        })
      })
    }).then(() => {
      let i = 0;
      return Promise.each(preminers, (preminer) => {
        return Promise.each(timestamps, (timestamp) => {
          return token.addPremineAllocation.sendTransaction(preminer.address, timestamp, {
            from: creator
          })
        })
      })
    })
  })

  it('Shouldnt allow to add same preminer two times', () => {
    return token.addPreminer.sendTransaction(preminers[0].address, preminers[0].balance, preminers[0].payment).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should contains preminers', () => {
    return Promise.each(preminers, preminer => {
      return token.getPreminer.call(preminer.address).then(preminerRawData => {
        const parsedPreminer = parser.parsePreminer(preminerRawData)

        assert.equal(parsedPreminer.payment.toString(10), preminer.payment)
        assert.equal(parsedPreminer.allocationsCount.toNumber(), duration)
      })
    })
  })


  it('Should contains preminers allocation timestamps', () => {
    return Promise.each(preminers, preminer => {
      let promises = []

      for (let i = 0; i < duration; i++) {
        promises.push(token.getPreminerAllocation.call(preminer.address, i))
      }

      return Promise.all(promises).then(timestamps => {
        return Promise.each(timestamps, (timestamp, index) => {
          assert.equal(timestamp.toNumber(), timestamps[index])
        })
      })

    })
  })

  it('Should complete allocation', () => {
    return token.allocate.sendTransaction(oneAcc, 0, {
      from: creator
    })
  })

  it('Shouldn\'t allow to preminer after allocation closed', () => {
    return token.addPreminer.sendTransaction(preminer.address, preminer.balance, preminer.payment, {
      from: creator
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Shouldn\'n allow to release new portion of premine now', () => {
    const preminerOne = preminers[0]

    return token.balanceOf.call(preminerOne.address).then((balance) => {
      return token.releasePremine.sendTransaction({
        from: creator
      }).then(() => balance)
    }).then((balance) => {
      return token.balanceOf.call(preminerOne.address).then((_balance) => {
        assert.equal(balance.toString(10), _balance.toString(10))
      })
    })
  })

  it('Should add new premine after each month', () => {
    const monthlySeconds = 2678500

    return Promise.each(preminers, (preminer) => {
      const releasePremine = () => {
        return time.move(web3, monthlySeconds).then(() => {
          return token.releasePremine.sendTransaction({
            from: preminer.address
          })
        })
      }

      const start = (i) => {
        return releasePremine().then(() => {
          i++;

          if (i <= duration) {
            return start(i)
          }

        })
      }

      return start(0).then(() => {
        return token.balanceOf(preminer.address)
      }).then(balance => {
        assert.equal(balance.toString(10), preminer.total)
      })
    })
  })

  it('Should doesnt allow new premine release after all premine reached closed', () => {
    const monthlySeconds = 2678500

    return time.move(web3, monthlySeconds).then(() => {
      return Promise.each(preminers, (preminer) => {
        return token.balanceOf(preminer.address).then((balance) => {
          return token.releasePremine.sendTransaction({
            from: preminer.address
          }).then(() => {
            return token.balanceOf(preminer.address)
          }).then(newBalance => {
            assert.equal(newBalance.toString(10), balance.toString(10))
          })
        })
      })
    })
  })

  it('Should allow to send user premine to another account', () => {
    return token.transfer.sendTransaction(preminer.address, preminers[0].total, {
      from: preminers[0].address
    }).then(() => {
      return token.balanceOf(preminer.address)
    }).then((balance) => {
      assert.equal(balance.toString(10), preminers[0].total)
    })
  })

})
