const Quadkey = artifacts.require("Quadkey");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "QuadKey";
  const symbol = "QK";
  const lands = "0x7Cd1e741d9A6af42C55bbCC17A40701e152A1Ef3";
  const baseLand = 180;
  deployer.deploy(Quadkey, creator, name, symbol, lands, baseLand)
    .then(qk => qk.addPauser(creator));
}
