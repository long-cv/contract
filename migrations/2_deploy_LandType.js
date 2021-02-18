const LandType = artifacts.require("LandType");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "Land Type";
  const symbol = "LTYPE";
  const landTypes = [1,30,60,180];
  const landIntervals = [1,30,60,180];
  deployer.deploy(LandType, creator, name, symbol, landTypes, landIntervals)
    .then(type => type.addPauser(creator));
}
