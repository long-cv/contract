//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface IQuadKey is IERC721, IERC721Enumerable, IERC721Metadata {
    function issueToken(address to, string memory tokenId, uint256 amount) external;

    function issueToken(address to, string memory tokenId, string memory landId, uint256 amount) external;

    function safeTransferFrom(address from, address to, string memory tokenId, string memory landId, uint256 amount, bytes memory data) external;

    function safeTransferFrom(address from, address to, string memory tokenId, string memory landId, uint256 amount) external;

    function transferFrom(address from, address to, string memory tokenId, string memory landId, uint256 amount) external;

    function getTokensOfOwner(address owner) external view returns(QuadKeyInfo[] memory);

    function isValidToken(string memory tokenId) external view returns(bool);
}