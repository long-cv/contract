const Quadkey = artifacts.require("Quadkey");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "QuadKey";
  const symbol = "QK";
  const lands = "0xC3cB481F400e6de09565c8be3DCABC7189E6a9dF";
  const baseLand = "180";
  deployer.deploy(Quadkey, creator, name, symbol, lands, baseLand)
    .then(qk => qk.addPauser(creator));
}
