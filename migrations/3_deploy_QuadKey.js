const Quadkey = artifacts.require("Quadkey");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "Quadkey";
  const symbol = "QK";
  const lands = "0x2FBf156604D63C6472e5d2132CFC12a0fd7c1783";
  const baseLand = 180;
  deployer.deploy(Quadkey, creator, name, symbol, lands, baseLand)
    .then(qk => qk.addPauser(creator));
}
