const Time = artifacts.require("Time");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const supply = 175000000000;
  const name = "Time";
  const symbol = "TIME";
  const decimals = 18;
  const ulimitedLockType = "unlimited";
  const lockTypeInterval = 300
  deployer.deploy(Time, creator, supply, name, symbol, decimals, ulimitedLockType, lockTypeInterval)
    .then(async token => {
      await token.addMinter(creator);
      await token.addPauser(creator);
    });
};
