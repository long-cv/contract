const Time = artifacts.require("Time");

module.exports = deployer => {
  const supplier = "0x45183f01794240bda150c127ec920b5e3a145f47";
  const creator1 = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const creator2 = "0x71a3691a7a868befeb4b23d6eb433cda301357e8";
  const creator3 = "0x92b55fc43578555ddeaa7c4e9acac443927cfadf";
  const supply = 175000000000;
  const name = "Time";
  const symbol = "TIME";
  const decimals = 6;
  const ulimitedLockType = 1;
  const lockTypeInterval = 180;
  deployer.deploy(Time, supplier, creator1, creator2, creator3, supply, name, symbol, decimals, ulimitedLockType, lockTypeInterval)
};
