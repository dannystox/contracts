const BigNumber = require('bignumber.js')
const Promise = require('bluebird')
const Token = artifacts.require("../contracts/Token.sol")
const MultiSigWallet = artifacts.require("../contracts/MultiSigWallet.sol")
const WingsMultisigFactory = artifacts.require("../contracts/MultiSigWallet/WingsMultisigFactory.sol")
const premine = require('./resources/premine.json')
const time = require('../helpers/time')
const errors = require('../helpers/errors')
const parser = require('../helpers/parser')
const abiHelper = require('../helpers/abi')

contract('Token/Premine', () => {
  const creator = web3.eth.accounts[0]
  const toSend = web3.toWei(100, 'ether')
  const multisigAccounts = web3.eth.accounts.slice(7, 9)

  let token, multisig

  const preminer = {
    "address": "0x8f9318230e6c4d416a0ad9bb9ce105bb74170b93",
    "recipient": "0x8f9318230e6c4d416a0ad9bb9ce105bb74170c93",
    "balance": "1031666670000000000000000",
    "payment": "104166660000000000000000",
    "duration": 26
  }

  const oneAcc = '0x8f9318230e6c4d416a0ad9bb9ce105bb74170c93'

  let preminers = []

  const duration = 26

  const timestamps = []


  const toSeconds = (time) => {
    return Math.floor(time / 1000)
  }

  before('Deploy Wings Token', () => {
    assert.notEqual(preminer.length, 0)


    const now = new Date()
    const month = now.getMonth()

    preminers = [{
      "address": web3.eth.accounts[0],
      "recipient": web3.eth.accounts[1],
      "balance": premine.balance,
      "payment": premine.payment,
      "total": premine.total
    }]


    console.log('Timestamps: ')
    for (let i = 1; i <= duration; i++) {
      let date = new Date()
      date.setMonth(month + i, 1)

      const timestamp = toSeconds(date.getTime())
      timestamps.push(timestamp)

      console.log(`#${i}: ${timestamp}\t|\t${date}`)
    }

    return WingsMultisigFactory.new().then(multisig => {
      return Promise.mapSeries(multisigAccounts, account => {
        return multisig.addAddress(account)
      }).then(() => {
        return multisig.create(2)
      }).then(() => {
        return multisig.multisig.call()
      })
    }).then(multisigAddress => {
      return MultiSigWallet.at(multisigAddress)
    }).then(_multisig => {
      multisig = _multisig

      return Token.new(preminers.length+1, multisig.address, {
        from: creator
      })
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
      return token.addPreminer(preminer.address, preminer.recipient, preminer.balance, preminer.payment, {
        from: creator
      })
    }).then((txId) => {
      return Promise.each(preminers, (preminer) => {
        return token.balanceOf.call(preminer.recipient).then(balance => {
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
    return token.addPreminer(preminers[0].address, preminers[0].recipient, preminers[0].balance, preminers[0].payment).then(() => {
      throw new Error('Code had to sent throw')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should contains preminers', () => {
    return Promise.each(preminers, preminer => {
      return token.getPreminer.call(preminer.address).then(preminerRawData => {
        const parsedPreminer = parser.parsePreminer(preminerRawData)

        assert.equal(parsedPreminer.disabled, false)
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

  it('Shouldn\'t allow to add new preminer after allocation closed', () => {
    return token.addPreminer(preminer.address, preminer.recipient, preminer.balance, preminer.payment, {
      from: creator
    }).then(() => {
      throw new Error('Code had to sent throw')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Shouldn\'n allow to release new portion of premine now', () => {
    const preminerOne = preminers[0]

    return token.balanceOf.call(preminerOne.recipient).then((balance) => {
      return token.releasePremine.sendTransaction({
        from: creator
      }).then(() => balance)
    }).then((balance) => {
      return token.balanceOf.call(preminerOne.recipient).then((_balance) => {
        assert.equal(balance.toString(10), _balance.toString(10))
      })
    })
  })

  it("Should release 50% of premine", () => {
    const partDuration = duration/2

    return Promise.each(preminers, (preminer) => {
      const releasePremine = (i) => {
        return time.blockchainTime(web3).then(blockchainTime => {
          const timeToMove = Math.abs(timestamps[i] - blockchainTime) + 3600

          return time.move(web3, timeToMove)
        }).then(() => {
          return token.releasePremine.sendTransaction({
            from: preminer.address
          })
        })
      }

      const start = (i) => {
        return releasePremine(i).then(() => {
          i++;

          if (i < partDuration) {
            return start(i)
          }

        })
      }

      return start(0).then(() => {
        return token.balanceOf(preminer.recipient)
      }).then(balance => {
        const afterMonthes = new BigNumber(preminer.balance).add(new BigNumber(preminer.payment).mul(partDuration))
        assert.equal(balance.toString(10), afterMonthes.toString(10))
      })
    })
  })

  it('Should disable premine from one account and move rest of premine on another', () => {
    const preminer = preminers[0];

    const functionName = 'disablePreminer(address,address,address)'
    const accounts = [
      preminer.address,
      web3.eth.accounts[1],
      web3.eth.accounts[2]
    ]

    let data = '0x' + abiHelper.getFunctionName(functionName)

    accounts.forEach(account => {
      data += abiHelper.getAddress(account)
    })

    return multisig.submitTransaction(
      token.address,
      0,
      data,
      {
        from: multisigAccounts[0]
      }
    ).then(result => {
      return multisig.transactionCount.call()
    }).then(txId => {
      txId = txId.toNumber()-1

      const restOfAccounts = multisigAccounts.slice(1)
      return Promise.each(restOfAccounts, account => {
        return multisig.confirmTransaction(0, {
          from: account
        })
      }).then(() => {
        return txId
      })
    }).then(txId => {
      return multisig.isConfirmed(txId).then(confirmed => {
        assert.equal(confirmed, true)
      })
    })
  })

  it('Should has preminer disabled', () => {
    return token.getPreminer(preminers[0].address).then(preminerRawData => {
      const parsedPreminer = parser.parsePreminer(preminerRawData)

      assert.equal(parsedPreminer.disabled, true)
    })
  })

  it('Shouldnt possible to release premine from disabled preminer', () => {
    return token.releasePremine({
      from: preminers[0].address
    }).then(() => {
      throw new Error('Should return JUMP error')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })


  it('Should contains another one preminer', () => {
    return Promise.join(
      token.getPreminer(web3.eth.accounts[0]),
      token.getPreminer(web3.eth.accounts[1]),
      (oldPreminerData, newPreminerData) => {
        const oldPreminer = parser.parsePreminer(oldPreminerData)
        const newPreminer = parser.parsePreminer(newPreminerData)

        assert.equal(oldPreminer.disabled, true)
        assert.equal(newPreminer.disabled, false)
        assert.equal(newPreminer.recipient, web3.eth.accounts[2])
        assert.equal(newPreminer.payment.toString(10), oldPreminer.payment.toString(10))
        assert.equal(newPreminer.latestAllocation.toString(10), oldPreminer.latestAllocation.toString(10))
        assert.equal(newPreminer.allocationsCount.toString(10), oldPreminer.allocationsCount.toString(10))
      }
    ).then(() => {
      preminers.push({
        address: web3.eth.accounts[1],
        recipient: web3.eth.accounts[2],
        balance: preminers[0].balance,
        payment: preminers[0].payment
      })
    })
  })

  it('Should contains new preminer allocations', () => {
    const preminer = preminers[1]
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

  it('Should release rest of premine', () => {
    let preminer = preminers[1]

    const releasePremine = (i) => {
      return time.blockchainTime(web3).then(blockchainTime => {
        const diff = Math.abs(timestamps[i] - blockchainTime) + 3600
        return time.move(web3, diff)
      }).then(() => {
        return token.releasePremine({
          from: preminer.address
        })
      })
    }

    const start = (i) => {
      return releasePremine(i).then(() => {
        i++;

        if (i < duration) {
          return start(i)
        }

      })
    }

    return start(duration/2).then(() => {
      return token.balanceOf(preminer.recipient)
    }).then(balance => {
      assert.equal(balance.toString(10), new BigNumber(preminer.payment).mul(duration/2).toString(10))
    })
  })

  it('Should allow to send user premine to another account', () => {
    let initialBalance

    return token.balanceOf(preminers[0].recipient).then(balance => {
      initialBalance = balance

      return token.transfer(preminers[1].address, balance, {
        from: preminers[0].recipient
      })
    }).then(() => {
      return token.balanceOf(preminers[1].address)
    }).then(balance => {
      assert.equal(balance.toString(10), initialBalance.toString(10))
    })

  })

  it('Should contains zero tokens at premine creator account', () => {
    return token.balanceOf.call(preminers[0].address).then(balance => {
      assert.equal(balance.toString(10), 0)
    })
  })

  it('Shouldnt allow to release more pre-mine on new account', () => {
    let initialBalance

    return token.balanceOf.call(preminers[1].recipient).then(balance => {
      initialBalance = balance

      return time.move(web3, 2419200*3)
    }).then(() => {
      return token.releasePremine({
        from: preminers[1].address
      })
    }).then(() => {
      return token.balanceOf(preminers[1].recipient)
    }).then(balance => {
      assert.equal(balance.toString(10), initialBalance.toString(10))
    })
  })

})
