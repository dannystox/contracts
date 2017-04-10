const Wings = artifacts.require("../contracts/Wings.sol")

module.exports = (deployer) => {
  return deployer.deploy(Wings)
}
