const Promise = require('bluebird')
const BigNumber = require('bignumber.js')
const Token = artifacts.require("../contracts/Token.sol")

contract('Token', () => {
  const creator = web3.eth.accounts[0]
  const toSend = web3.toWei(100, 'ether')

  let token

  before('Deploy Wings Token', () => {
    return Token.new(web3.eth.accounts.length, {
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
    return token.allocation.call().then((allocation) => {
      assert.equal(allocation, true)
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
    return Promise.each(web3.eth.accounts, account => {
      return token.allocate.sendTransaction(account, toSend, {
        from: creator
      })
    })
  })

  it('Should has accounts balances', () => {
    return Promise.each(web3.eth.accounts, account => {
      return token.balanceOf.call(account).then((balance) => {
        assert.equal(balance.toString(10), toSend.toString(10))
      })
    })
  })

  it('Should doesn\'t allow to send tokens while allocation running', () => {
    return token.transfer.sendTransaction(web3.eth.accounts[1], toSend, {
      from: creator
    }).then(() => {
      return token.balanceOf.call(creator)
    }).then(balance => {
      assert.equal(balance.toString(10), toSend.toString(10))
    })
  })

  it('Should doesn\'t allow to add spender account while allocation running', () => {
    return token.approve.sendTransaction(web3.eth.accounts[1], toSend, {
      from: creator
    }).then(() => {
      return token.transferFrom.sendTransaction(creator, web3.eth.accounts[2], toSend, {
        from: web3.eth.accounts[1]
      })
    }).then(() => {
      return Promise.all([
        token.balanceOf.call(creator),
        token.balanceOf.call(web3.eth.accounts[2])
      ])
    }).then((balances) => {
      balances.forEach(balance => {
        assert.equal(balance.toString(10), toSend.toString(10))
      })
    })
  })

  it('Should complete allocation', () => {
    return token.completeAllocation.sendTransaction().then(() => {
      return token.allocation.call()
    }).then((allocation) => {
      assert.equal(allocation, false)
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
      return token.balanceOf(web3.eth.accounts[3])
    }).then((balance) => {
      assert.equal(balance.toString(10), toSend.toString(10))
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
