const Time = artifacts.require("Time");

module.exports = function(deployer) {
  deployer.deploy(Time, "0x7D2c112b3DDB209F81f7d294Fe6196552F3c9C35", 175000000000, "Time", "TIME", 18);
};
