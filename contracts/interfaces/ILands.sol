//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface ILands is IERC721, IERC721Enumerable, IERC721Metadata {
    function issueToken(address to, string memory tokenId, uint256 amount) external;

    function getTokensOfOwner(address owner) external view returns(Tokens[] memory);

    function getTokenTimestamp(address owner, string memory tokenId) external view returns(uint64);

    function updateTokenTimestamp(address owner, string memory tokenId, uint64 newTimestamp) external;
}