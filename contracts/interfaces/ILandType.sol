//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC721Metadata.sol";
import "../struct/struct.sol";

interface ILandType is IERC721Metadata {
    event Transfer(address indexed from, address indexed to, string quadkey, uint16 tokenId, uint256 amount);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event UpgradeLand(address indexed owner, string quadkey, uint16 fromLandId, uint16 toLandId, uint256 amount);

    function isOwnerOf(address owner, string memory quadkey, uint16 tokenId) external view returns (bool);

    function transferFrom(address from, address to, string memory quadkey, uint16 tokenId, uint176 amount) external returns(bool);
   
    function setApprovalForAll(address operator, bool approved) external returns(bool);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function totalSupply() external view returns (uint256, uint256);

    function tokenByIndex(uint256 index) external view returns (uint16);

    function tokenOfOwnerByIndex(address owner, string memory quadkey, uint256 index) external view returns (LandInfo memory);

    function tokenIndexOfOwnerById(address owner, string memory quadkey, uint16 tokenId) external view returns (uint256);

    function createToken(uint16 tokenId, uint64 interval) external returns(bool);

    function getTokenIDs() external view returns(uint16[] memory);

    function upgradeLand(address owner, string memory quadkey, uint16 fromLandId, uint16 toLandId, uint176 amount) external returns(bool);

    function issueToken(address to, string memory quadkey, uint16 tokenId, uint176 amount) external returns(bool);

    function getTokensOfOwner(address owner, string memory quadkey) external view returns(LandInfo[] memory);

    function updateTokenTimestamp(address owner, string memory quadkey, uint16 tokenId, uint64 newTimestamp) external returns(bool);

    function getTokenInterval(uint16 tokenId) external view returns(uint64);

}