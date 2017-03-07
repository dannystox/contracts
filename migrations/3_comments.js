const Comments = artifacts.require("../contracts/newversion/comments/BasicComment.sol")

module.exports = (deployer) => {
  return deployer.deploy(Comments)
}
