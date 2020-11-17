const Time = artifacts.require("Time");

module.exports = function(deployer) {
  deployer.deploy(Time, 175000000000, "Time", "TIM", 18);
};
