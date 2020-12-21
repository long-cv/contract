const Manager = artifacts.require("Manager");

module.exports = function(deployer) {
    deployer.deploy(Manager, "0x7D2c112b3DDB209F81f7d294Fe6196552F3c9C35", "0x5B2979aA3C213D5cE0EF041d6b38413f614B7e33", "0x5BEBe6C403A3a722fB4850f8d622ca734DFc2B33", "0x03375162Bc7b26BA89574BA2B70818383c96B9b0");    
}
