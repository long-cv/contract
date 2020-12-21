const Lands = artifacts.require("Lands");

module.exports = function(deployer) {
    deployer.deploy(Lands, "0x7D2c112b3DDB209F81f7d294Fe6196552F3c9C35", "Lands", "Lands", ["1","30","60","180"], [1,30,60,180]);    
}
