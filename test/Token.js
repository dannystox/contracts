const Promise = require('bluebird')
const BigNumber = require('bignumber.js')
const Token = artifacts.require("../contracts/Token.sol")
const MultiSigWallet = artifacts.require("../contracts/MultiSigWallet.sol")
const WingsMultisigFactory = artifacts.require("../contracts/MultiSigWallet/WingsMultisigFactory.sol")

const errors = require('../helpers/errors')

contract('Token', () => {
  const creator = web3.eth.accounts[0]
  const toSend = web3.toWei(100, 'ether')
  const multisigAccounts = web3.eth.accounts.slice(8, 9)

  let token, multisig

  before('Deploy Wings Token', () => {
    return WingsMultisigFactory.new().then(multisig => {
      return Promise.mapSeries(multisigAccounts, account => {
        return multisig.addAddress(account)
      }).then(() => {
        return multisig.create(1)
      }).then(() => {
        return multisig.multisig.call()
      })
    }).then(multisigAddress => {
      return MultiSigWallet.at(multisigAddress)
    }).then(_multisig => {
      multisig = _multisig

      return Token.new(web3.eth.accounts.length, multisig.address, {
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

  it('Check total supply', () => {
    return token.totalSupply.call(totalSupply => {
      assert.equal(totalSupply.toString(10), web3.toWei(100000000, 'ether'))
    })
  })

  it('Allocation should be equal \'true\'', () => {
    return token.accountsToAllocate.call().then((allocation) => {
      assert.equal(allocation.gt(0), true)
    })
  })


  it('Should\'t allow to allocate coins from another account', () => {
    return Promise.each(web3.eth.accounts, account => {
      return token.allocate.sendTransaction(account, toSend, {
        from: web3.eth.accounts[1]
      })
    }).then(() => {
      return Promise.each(web3.eth.accounts, account => {
        return token.balanceOf.call(account).then((balance) => {
          assert.equal(balance.toString(10), '0')
        })
      })
    })
  })

  it(`Should allow to allocate ${toSend.toString()} coins to each available account`, () => {
    const accounts = web3.eth.accounts.slice(0, 2)
    return Promise.each(accounts, (account) => {
      return token.allocate.sendTransaction(account, toSend, {
        from: creator
      })
    })
  })

  it('Should has accounts balances', () => {
    const accounts = web3.eth.accounts.slice(0, 2)

    return Promise.each(accounts, account => {
      return token.balanceOf.call(account).then((balance) => {
        assert.equal(balance.toString(10), toSend.toString(10))
      })
    })
  })


  it('Shouldnt allow to allocate same account two times', () => {
    const account = web3.eth.accounts[0]

    return token.allocate.sendTransaction(account, toSend, {
      from: creator
    }).then(() => {
      throw new Error('Code had to sent throw')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should doesn\'t allow to send tokens while allocation running', () => {
    return token.transfer.sendTransaction(web3.eth.accounts[1], toSend, {
      from: creator
    }).then(() => {
      throw new Error('Code had to sent throw')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should doesn\'t allow to add spender account while allocation running', () => {
    return token.approve.sendTransaction(web3.eth.accounts[1], toSend, {
      from: creator
    }).then(() => {
      throw new Error('Code had to sent throw')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it(`Should allow to allocate ${toSend.toString()} coins to reast of available account`, () => {
    const accounts = web3.eth.accounts.slice(2)
    return Promise.each(accounts, (account) => {
      return token.allocate.sendTransaction(account, toSend, {
        from: creator
      })
    })
  })


  it('Should allow to transfer tokens when allocation closed', () => {
    return token.transfer.sendTransaction(web3.eth.accounts[1], toSend, {
      from: creator
    }).then((txId) => {
      return Promise.join(
        token.balanceOf.call(creator),
        token.balanceOf.call(web3.eth.accounts[1]),
        (creatorBalance, userBalance) => {
          assert.equal(creatorBalance.toString(10), '0')
          assert.equal(userBalance.toString(10), new BigNumber(toSend).mul(2).toString(10))
        }
      )
    })
  })

  it('Should doesnt\' allow to allocate new coins after allocation closed', () => {
    return token.allocate.sendTransaction(web3.eth.accounts[3], new BigNumber(toSend).mul(2), {
      from: creator
    }).then(() => {
      throw new Error('Code had to sent throw')
    }).catch(err => {
      assert.equal(errors.isJump(err.message), true)
    })
  })

  it('Should allow to approve sender when allocation closed', () => {
    return token.approve.sendTransaction(web3.eth.accounts[3], web3.toWei(3, 'ether'), {
      from: web3.eth.accounts[1]
    }).then(() => {
      return token.transferFrom.sendTransaction(web3.eth.accounts[1], web3.eth.accounts[3], web3.toWei(3, 'ether'), {
        from: web3.eth.accounts[3]
      })
    }).then(() => {
      return token.balanceOf(web3.eth.accounts[3])
    }).then((balance) => {
      assert.equal(balance.toString(10), new BigNumber(toSend).add(web3.toWei(3, 'ether')).toString(10))
    })
  })

})
