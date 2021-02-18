const Manager = artifacts.require("Manager");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";

  const time = "0x1A0a3eD924BD5C2A5BFEa87Fb7bD557eD4C1517E";
  const landType = "0x2B85abdA7f6DF7D37B47437C375e3320d8A4FB50";
  const land = "0x9F9ac04ad355903289874D9461e0598aa09E5fe3";

  const landPrice = 1;
  const upgradableBasePrice = 1;
  const intervalKind = 1;
  
  deployer.deploy(Manager, creator, time, landType, land, landPrice, upgradableBasePrice, intervalKind);
}
