const Lands = artifacts.require("Lands");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "Lands";
  const symbol = "LAND";
  const landIDs = ["1","30","60","180"];
  const landIntervals = [1,30,60,180];
  deployer.deploy(Lands, creator, name, symbol, landIDs, landIntervals)
    .then(lands => lands.addPauser(creator));
}
