const QuadKey = artifacts.require("QuadKey");

module.exports = deployer => {
  const creator = "0x743daf3b561f35bfc21b239d336c2d24581a16b4";
  const name = "QuadKey";
  const symbol = "QK";
  const lands = "0x38043F2443fA0c47948d11a03cDF6429473d117A";
  const baseLand = "180";
  deployer.deploy(QuadKey, creator, name, symbol, lands, baseLand)
    .then(qk => qk.addPauser(creator));
}
