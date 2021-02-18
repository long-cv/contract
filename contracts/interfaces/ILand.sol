//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface ILand is IERC721, IERC721Enumerable, IERC721Metadata {
    function issueToken(address to, string memory tokenId, uint176 amount) external returns(bool);

    function issueToken(address to, string memory tokenId, uint16 landId, uint176 amount) external returns(bool);

    function transferFrom(address from, address to, string memory tokenId, uint16 landId, uint176 amount) external returns(bool);

    function getTokensOfOwner(address owner) external view returns(string[] memory);

    function getTokenAmountOfOwner(address owner, string memory tokenId) external view returns(uint256);

    function isValidToken(string memory tokenId) external view returns(bool);
}