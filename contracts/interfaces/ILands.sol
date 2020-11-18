//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface ILands is IERC721, IERC721Enumerable, IERC721Metadata {
    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev check if token id is duplicated, or null or burned. Throw if msg.sender is not creator
    /// @param tokenIDs array of extra tokens to mint.
    /// @param tokenWeights weight of each token.
    function issueToken(string[] memory tokenIDs, uint8[] memory tokenWeights) external;

    /// @notice burn a token, can only be called by contract creator
    /// @dev throw unless msg.sender is creator and owner is creator.
    /// throw if token is not valid
    /// @param tokenId id of token.
    function burnToken(string memory tokenId) external;
    /// @notice get list of token ids of an owner
    /// @dev throw if 'owner' is zero address
    /// @param owner address of owner
    /// @return list of token ids of owner
    function getTokenIDsOfOwner(address owner) external view returns(string[] memory);

    /// @notice get token weight
    /// @dev throw if token is not valid
    /// @param tokenId id of the token
    /// @return token weight
    function getTokenWeight(string memory tokenId) external view returns(uint8);

    /// @notice get token timestamp
    /// @dev throw if token is not valid
    /// @param tokenId id of the token
    /// @return token timestamp
    function getTokenTimestamp(string memory tokenId) external view returns(uint64);

    /// @notice change the token weight. only creator can change it
    /// @dev throw unless msg.sender is creator and token id is valid.
    /// @param tokenId id of token
    /// @param newWeight new value of token weight
    function updateTokenWeight(string memory tokenId, uint8 newWeight) external;

    /// @notice change the token timestamp. only creator can change it
    /// @dev throw unless token id is valid.
    /// @param tokenId id of token
    /// @param newTimestamp new value of token timestamp
    function updateTokenTimestamp(string memory tokenId, uint64 newTimestamp) external;
}