module.exports = function(deployer) {
  deployer.deploy(Token);
  deployer.deploy(Wings);
  deployer.deploy(WingsCrowdsale);
  //deployer.deploy(Token);
  //deployer.autolink();
};
