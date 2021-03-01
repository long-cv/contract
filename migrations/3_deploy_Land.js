const Land = artifacts.require("Land");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "Land";
  const symbol = "LAND";
  const landType = "0x2B85abdA7f6DF7D37B47437C375e3320d8A4FB50";
  const baseLandType = 180;
  
  deployer.deploy(Land, creator, name, symbol, landType, baseLandType)
    .then(land => land.addPauser(creator));
}
