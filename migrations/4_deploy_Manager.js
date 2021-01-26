const Manager = artifacts.require("Manager");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";

  const time = "0xE549e4207c4b3afc31eC411420f452Fc15576A81";
  const lands = "0x2FBf156604D63C6472e5d2132CFC12a0fd7c1783";
  const quadkey = "0x6884E70cebBbf8bBcAC835076FF41C2ea2736Cd1";

  const landPrice = 1;
  const upgradableBasePrice = 1;
  const intervalKind = 1;
  
  deployer.deploy(Manager, creator, time, lands, quadkey, landPrice, upgradableBasePrice, intervalKind);
}
