const Lands = artifacts.require("Lands");

module.exports = function(deployer) {
    deployer.deploy(Lands, "Lands", "LT");    
}
