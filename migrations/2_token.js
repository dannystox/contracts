const Token = artifacts.require("../contracts/Token.sol")

module.exports = (deployer) => {
  return deployer.deploy(Token, 1)
}
