const Pairs = artifacts.require("Pairs");

module.exports = function(deployer) {
    deployer.deploy(Pairs, "0x4E2500890bb8467FD4cf94FC8B311205F30FA5e0", "0xDEA11C95eD167563F2BB439e5Ce520f11196b9a3");    
}
