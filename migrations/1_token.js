const Promise = require('../node_modules/bluebird/js/release/bluebird.js')
const Token = artifacts.require("../contracts/Token.sol")
const Wings = artifacts.require('../contracts/Wings.sol')

module.exports = (deployer) => {
  const creator = web3.eth.accounts[0]

  return deployer.deploy(Token, 1, creator).then(() => {
    return Token.deployed()
  }).then(token => {
    return token.allocate(creator, web3.toWei(100000000, 'ether')).then(() => token)
  }).then(token => {
    return deployer.deploy(Wings, token.address)
  })
}
