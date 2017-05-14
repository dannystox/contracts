const BigNumber = require('bignumber.js')
const Promise = require('bluebird')
const Token = artifacts.require("../contracts/Token.sol")
const MultiSigWallet = artifacts.require("../contracts/MultiSigWallet.sol")
const WingsMultisigFactory = artifacts.require("../contracts/MultiSigWallet/WingsMultisigFactory.sol")
const fs = require('fs')
const csv = require('csv-parser')

contract('Token/LargeAllocation', () => {
  const creator = web3.eth.accounts[0]
  const toSend = web3.toWei(100, 'ether')
  const multisigAccounts = web3.eth.accounts.slice(8, 9)

  let token, multisig

  const accountsCount = 10000

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

      return Token.new(accountsCount, multisig.address, {
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
      assert.equal(allocation.toNumber(), accountsCount)
    })
  })

  // rewrite on promises
  it('Should be possible to allocate 10000 accounts', (done) => {
    const stream = fs.createReadStream('./test/resources/accounts.csv')
    const csvStream = csv()

    stream
      .pipe(csvStream)
      .on('data', function (data) {
        csvStream.pause()

        const { Address, Balance } = data

        return token.allocate.sendTransaction(Address, Balance, {
          from: creator
        }).then(() => {
          csvStream.resume()
        }).catch(err => {
          csvStream.destroy()
          stream.destroy()
          done(err)
        })
      }).on('end', done).on('error', done)
  })

  it('Should contains written data', (done) => {
    const stream = fs.createReadStream('./test/resources/accounts.csv')
    const csvStream = csv()

    stream
      .pipe(csvStream)
      .on('data', function (data) {
        csvStream.pause()

        const { Address, Balance } = data

        return token.balanceOf.call(Address).then((balance) => {
          assert.equal(balance.toString(10), Balance.toString(10))
          csvStream.resume()
        }).catch(err => {
            csvStream.destroy()
            stream.destroy()
            done(err)
        })
      }).on('end', done).on('error', done)
  })
})
