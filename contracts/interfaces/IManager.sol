//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../struct/struct.sol";

interface IManager {
    event ClaimRewardOfLand(address indexed owner, string quadkey, uint16 landId, uint256 reward);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, string quadkey, uint16 landId, uint256 amount);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getLandPrice(uint256 amount) external view returns(uint256);

    function buyLand(string memory quadkey, uint176 amount) external;

    function getUpgradableLandPrice(uint16 fromLandId, uint16 toLandId, uint256 amount) external view returns(uint256);

    function upgradeLand(string memory quadkey, uint16 fromLandId, uint16 toLandId, uint176 amount) external;

    function issueLand(address to, string memory quadkey, uint176 amount) external;

    function issueLand(address to, string memory quadkey, uint16 landId, uint176 amount) external;

    function transferLandFrom(address from, address to, string memory quadkey, uint16 landId, uint176 amount) external;

    function getLandIntervalList() external view returns(string memory Intervals);
    
    function getLandList(address owner) external view returns(string memory list);

    function claimLandReward(address owner, string memory quadkey, uint16 landId) external;

    function claimQuadkeyReward(address owner, string memory quadkey) external;

    function claimAllReward(address owner) external;
}