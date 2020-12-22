// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '../struct/struct.sol';

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (Supplies memory);

    function tokenByIndex(uint256 index) external view returns (string memory);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (QuadKeyInfo memory);

    function tokenIndexOfOwnerById(address owner, string memory tokenId) external view returns (uint256);
}