const Manager = artifacts.require("Manager");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const time = "0x35ED34260A798fC9d7f0DE48E5510295205ad76A";
  const lands = "0xC3cB481F400e6de09565c8be3DCABC7189E6a9dF";
  const quadkey = "0x1152E43E5360DffDB0b509c2239f4198c5A78ADA";
  const landPrice = 1;
  const upgradableBasePrice = 1;
  const intervalKind = 1;
  
  deployer.deploy(Manager, creator, time, lands, quadkey, landPrice, upgradableBasePrice, intervalKind);
}
