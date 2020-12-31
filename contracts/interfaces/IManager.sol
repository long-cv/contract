//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../struct/struct.sol";

interface IManager {
    
    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReserve(address owner) external view returns(uint256);

    function getLandPrice(uint256 amount) external view returns(uint256);

    function buyLand(string memory quadkey, uint256 amount) external;

    function getUpgradableLandPrice(string memory fromLandId, string memory toLandId, uint256 amount) external view returns(uint256);

    function upgradeLand(string memory quadkey, string memory fromLandId, string memory toLandId, uint256 amount) external;

    function issueLand(address to, string memory quadkey, uint256 amount) external;

    function issueLand(address to, string memory quadkey, string memory landId, uint256 amount) external;

    function transferLandFrom(address from, address to, string memory quadkey, string memory landId, uint256 amount) external;

    function getLandIntervalList() external view returns(string memory Intervals);
    
    function getLandList(address owner) external view returns(string memory list);

    function claimLandReward(address owner, string memory quadkey, string memory landId) external;

    function claimQuadkeyReward(address owner, string memory quadkey) external;

    function claimAllReward(address owner) external;
}