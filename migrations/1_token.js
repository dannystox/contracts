const Promise = require('../node_modules/bluebird/js/release/bluebird.js')
const Token = artifacts.require("../contracts/Token.sol")
const WingsMultisigFactory = artifacts.require("../contracts/MultiSigWallet/WingsMultisigFactory.sol")

module.exports = (deployer) => {
  let multisig
  const accounts = web3.eth.accounts.slice(8, 9)

  return deployer.deploy(WingsMultisigFactory).then(() => {
    return WingsMultisigFactory.deployed()
  }).then(_multisig => {
    multisig = _multisig

    return Promise.mapSeries(accounts, account => {
      return multisig.addAddress(account)
    })
  }).then(() => {
    return multisig.create(1)
  }).then(() => {
    return multisig.multisig.call()
  }).then(multisigAddress => {
    return deployer.deploy(Token, 1, multisigAddress)
  })
}
