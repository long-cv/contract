const Pairs = artifacts.require("Pairs");

module.exports = function(deployer) {
    deployer.deploy(Pairs, "0x6594526156180046c68A67316e80fd6FC47c48E2", "0x59C50F2883C2654107C33cf0f8170A9C0A8B03fe", "Pairs", "TAL", 18);    
}
