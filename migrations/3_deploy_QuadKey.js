const QuadKey = artifacts.require("QuadKey");

module.exports = function(deployer) {
    deployer.deploy(QuadKey, 
        "0x7D2c112b3DDB209F81f7d294Fe6196552F3c9C35", // creator
        "QuadKey", "QK", 
        "", // lands
        "180");    
}
