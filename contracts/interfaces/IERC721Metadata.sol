// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory __name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory __symbol);
}