/* global Token, Wings, WingsCrowdsale */
const Token = artifacts.require("../contracts/Token.sol")
const Storage = artifacts.require("../contracts/storage/Storage.sol")
const BasicComment = artifacts.require("../contracts/comments/BasicComment.sol")
const Wings = artifacts.require("../contracts/Wings.sol")
const WingsCrowdsale = artifacts.require("../contracts/WingsCrowdsale.sol")

module.exports = (deployer) => {
  deployer.deploy(Token).then(() => {
    return deployer.deploy(Storage)
  }).then(() => {
    return Storage.deployed()
  }).then((storage) => {
    return deployer.deploy(BasicComment, storage.address).then(() => {
      return storage.addMember.sendTransaction(BasicComment.address)
    })
  }).then(() => {
    return deployer.deploy(Wings, BasicComment.address)
  }).then(() => {
    return deployer.deploy(WingsCrowdsale)
  })
}
