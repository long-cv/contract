const ERC721Full = artifacts.require("ERC721Full");

module.exports = function(deployer) {
    deployer.deploy(ERC721Full, 10, "DK Coin", "DKC721", "https://dk.com.vn/");    
}
