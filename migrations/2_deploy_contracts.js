/* global Token, Wings, WingsCrowdsale */

module.exports = (deployer) => {
  deployer.deploy(Token).then(() => {
    return deployer.deploy(Storage)
  }).then(() => {
    let storage = Storage.deployed()

    return deployer.deploy(BasicComment, storage.address).then(() => {
      return storage.addMember.sendTransaction(BasicComment.address)
    })
  }).then(() => {
    return deployer.deploy(Wings, BasicComment.address)
  }).then(() => {
    return deployer.deploy(WingsCrowdsale)
  })
  // deployer.deploy(Token)
  // deployer.autolink()
}
