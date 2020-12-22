const Manager = artifacts.require("Manager");

module.exports = function(deployer) {
    // constructor(address creator, address time, address lands, address quadkey, uint256 landPrice, uint256 upgradableBasePrice, uint64 intervalKind)
    deployer.deploy(
        Manager,
        "0x7D2c112b3DDB209F81f7d294Fe6196552F3c9C35", // creator
        "0x5B2979aA3C213D5cE0EF041d6b38413f614B7e33", // time
        "0xDA6e2671BCbFcF8C7F468A3645e96177c7B1514F", // lands
        "0x643a046337545440F0354caCd3A41d5B2f70003A", // quadkey
        1, 1, 1
    );    
}
