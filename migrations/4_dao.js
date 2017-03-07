const DAO = artifacts.require("../contracts/newversion/DAO.sol")

module.exports = (deployer) => {
  return deployer.deploy(DAO)
}
