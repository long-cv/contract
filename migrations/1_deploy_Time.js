const Time = artifacts.require("Time");

module.exports = deployer => {
  const supplier = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const creator1 = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const creator2 = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const creator3 = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const supply = 175000000000;
  const name = "Time";
  const symbol = "TIME";
  const decimals = 6;
  const ulimitedLockType = 1;
  const lockTypeInterval = 180;
  deployer.deploy(Time, supplier, creator1, creator2, creator3, supply, name, symbol, decimals, ulimitedLockType, lockTypeInterval)
};
