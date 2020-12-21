//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC721Metadata.sol";
import "../struct/struct.sol";

interface ILands is IERC721Metadata {
    event Transfer(address indexed from, address indexed to, string quadkey, string tokenId, uint256 amount);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function isOwnerOf(address owner, string memory quadkey, string memory tokenId) external view returns (bool);

    function safeTransferFrom(address from, address to, string memory quadkey, string memory tokenId, uint256 amount, bytes memory data) external;

    function safeTransferFrom(address from, address to, string memory quadkey, string memory tokenId, uint256 amount) external;

    function transferFrom(address from, address to, string memory quadkey, string memory tokenId, uint256 amount) external;
   
    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function totalSupply() external view returns (Supplies memory);

    function tokenByIndex(uint256 index) external view returns (string memory);

    function tokenOfOwnerByIndex(address owner, string memory quadkey, uint256 index) external view returns (Tokens memory);

    function tokenIndexOfOwnerById(address owner, string memory quadkey, string memory tokenId) external view returns (uint256);

    function createToken(string memory tokenId, uint64 interval) external;

    function getTokenIDs() external view returns(string[] memory);

    function issueToken(address to, string memory quadkey, string memory tokenId, uint256 amount) external;

    function getTokensOfOwner(address owner, string memory quadkey) external view returns(Tokens[] memory);

    function updateTokenTimestamp(address owner, string memory quadkey, string memory tokenId, uint64 newTimestamp) external;

    function getTokenInterval(string memory tokenId) external view returns(uint64);

}