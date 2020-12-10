//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when number of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed from, address indexed to, string indexed tokenId, uint256 amount);

    /// @dev This emits when the spender address is approved an amount of NFT.
    event Approval(address indexed owner, address indexed spender, string indexed tokenId, uint256 amount);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner An address for whom to query the balance
    /// @return The number of NFTs owned by `owner`, possibly zero
    function balanceOf(address owner) external view returns (uint256);

    function isOwnerOf(address owner, string memory tokenId) external view returns (bool);

    function safeTransferFrom(address from, address to, string memory tokenId, uint256 amount, bytes memory data) external;

    function safeTransferFrom(address from, address to, string memory tokenId, uint256 amount) external;

    function transferFrom(address from, address to, string memory tokenId, uint256 amount) external;

    function approve(address owner, address spender, string memory tokenId, uint256 amount) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(address owner, address spender, string memory tokenId) external view returns (uint256);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}