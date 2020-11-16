const TokenERC20 = artifacts.require("TokenERC20");

module.exports = function(deployer) {
  deployer.deploy(TokenERC20, 175000000000, "Test Token B", "TTB", 18);
};
