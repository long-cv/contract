// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC165.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/ILands.sol";
import "./libraries/SafeMath.sol";
import "./Pausable.sol";

contract Lands is ERC165, ILands, Pausable {
    using SafeMath for uint256;

    address internal _creator;
    
    mapping(address => uint256) internal _balances;
    mapping(string => address) internal _owners;
    mapping(string => address) internal _allowance;
    mapping(address => mapping(address => bool)) internal _authorised;

    string private _name;
    string private _symbol;

    mapping(address => string[]) internal _ownerTokenIDs; // array of tokenId of a owner
    mapping(string => uint256) internal _ownerTokenIndexes; // index of tokenId in array of tokenId of a owner
    
    string[] internal _tokenIDs; // array of tokenId
    mapping(string => uint8) internal _tokenWeights; // weight of each token
    mapping(string => uint64) internal _tokenTimestamps; // timestamp at the moment user becomes owner of a token
    mapping(string => uint256) internal _tokenIndexes; // index of tokenId in array of tokenId
    mapping(string => bool) internal _created; // token is created
    mapping(string => bool) internal _burned; // token is burned

    /// @notice Contract constructor
    /// @param name The name of token
    /// @param symbol The symbol of token
    constructor(string memory name, string memory symbol) ERC165() {
        _creator = msg.sender;

        _name = name;
        _symbol = symbol;

        //Add to ERC165 Interface Check
        _supportedInterfaces[
            this.balanceOf.selector ^
            this.ownerOf.selector ^
            bytes4(keccak256("safeTransferFrom(address,address,string,bytes)")) ^
            bytes4(keccak256("safeTransferFrom(address,address,string)")) ^
            this.transferFrom.selector ^
            this.approve.selector ^
            this.setApprovalForAll.selector ^
            this.getApproved.selector ^
            this.isApprovedForAll.selector ^
            this.totalSupply.selector ^
            this.tokenByIndex.selector ^
            this.tokenOfOwnerByIndex.selector ^
            this.name.selector ^
            this.symbol.selector
        ] = true;
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address owner) external override view returns (uint256) {
        return _balances[owner];
    }

    /// @notice Find the owner of an NFT
    /// @param tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(string memory tokenId) public override view returns (address) {
        require(isValidToken(tokenId));
        
        if (_owners[tokenId] != address(0)) {
            return _owners[tokenId];
        } else {
            return _creator;
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,string,bytes)"))`.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `to`
    function safeTransferFrom(address from, address to, string memory tokenId, bytes memory data) public override whenNotPaused {
        transferFrom(from, to, tokenId);

        //Get size of "to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(to)
        }

        if (size > 0) {
            IERC721TokenReceiver receiver = IERC721TokenReceiver(to);
            require(receiver.onERC721Received(msg.sender, from, tokenId, data) == bytes4(keccak256("onERC721Received(address,address,string,bytes)")));
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function safeTransferFrom(address from, address to, string memory tokenId) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner or not creator. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function transferFrom(address from, address to, string memory tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(from == _creator && from == owner, "transferFrom: not from creator");
        require(msg.sender == _creator || msg.sender == _allowance[tokenId] || _authorised[owner][msg.sender], "transferFrom: not have permission");
        require(from != to, "transferFrom: from and to address are same.");
        require(address(0) != to, "transferFrom: transfer to zero address.");
        require(isValidToken(tokenId), "transferFrom: token id is invalid");

        emit Transfer(from, to, tokenId);

        _owners[tokenId] = to;
        _balances[from]--;
        _balances[to] = _balances[to].add(1);

        //Reset approved if there is one
        if (_allowance[tokenId] != address(0)) {
            delete _allowance[tokenId];
        }

        uint256 oldIndex = _ownerTokenIndexes[tokenId];
        uint256 lastIndex = _ownerTokenIDs[from].length - 1;
        if (oldIndex != lastIndex) {
            string memory lastTokenId = _ownerTokenIDs[from][lastIndex];
            _ownerTokenIDs[from][oldIndex] = lastTokenId;
            _ownerTokenIndexes[lastTokenId] = oldIndex;
        }
        _ownerTokenIDs[from].pop();
        _ownerTokenIndexes[tokenId] = _ownerTokenIDs[to].length;
        _ownerTokenIDs[to].push(tokenId);
        
        _tokenTimestamps[tokenId] = uint64(block.timestamp % 2**64);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param approved The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(address approved, string memory tokenId) external override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || _authorised[owner][msg.sender]);

        emit Approval(owner, approved, tokenId);

        _allowance[tokenId] = approved;
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external override whenNotPaused {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(string memory tokenId) external override view returns (address) {
        require(isValidToken(tokenId), "getApproved: token id is invalid");

        return _allowance[tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address owner, address operator) external override view returns (bool) {
        return _authorised[owner][operator];
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external override view returns (uint256) {
        return _tokenIDs.length;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `index` >= `totalSupply()`.
    /// @param index A counter less than `totalSupply()`
    /// @return The token identifier for the `index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 index) external override view returns (string memory) {
        require(index < _tokenIDs.length);
        return _tokenIDs[index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index` >= `balanceOf(owner)` or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param index A counter less than `balanceOf(owner)`
    /// @return The token identifier for the `index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address owner, uint256 index) external override view returns (string memory) {
        require(index < _balances[owner], "tokenOfOwnerByIndex: index is invalid");
        return _ownerTokenIDs[owner][index];
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external override view returns (string memory __name) {
        __name = _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external override view returns (string memory __symbol) {
        __symbol = _symbol;
    }

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev check if token id is duplicated, or null or burned. Throw if msg.sender is not creator
    /// @param tokenIDs array of extra tokens to mint.
    /// @param tokenWeights weight of each token.
    function issueToken(string[] memory tokenIDs, uint8[] memory tokenWeights) public override whenNotPaused {
        require(msg.sender == _creator, "issueToken: not have permission.");
        _balances[msg.sender] = _balances[msg.sender].add(tokenIDs.length);

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (bytes(tokenIDs[i]).length > 0 && !_created[tokenIDs[i]] && !_burned[tokenIDs[i]]) {
                _ownerTokenIndexes[tokenIDs[i]] = _ownerTokenIDs[_creator].length;
                _ownerTokenIDs[_creator].push(tokenIDs[i]);

                _tokenIndexes[tokenIDs[i]] = _tokenIDs.length;
                _tokenIDs.push(tokenIDs[i]);

                _tokenWeights[tokenIDs[i]] = tokenWeights[i];

                _created[tokenIDs[i]] = true;

                //Move event emit into this loop to save gas
                emit Transfer(address(0), _creator, tokenIDs[i]);
            } else {
                _balances[msg.sender] = _balances[msg.sender].sub(1);
            }
        }
    }

    /// @notice burn a token, can only be called by contract creator
    /// @dev throw unless msg.sender is creator and owner is creator.
    /// throw if token is not valid
    /// @param tokenId id of token.
    function burnToken(string memory tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == _creator && owner == _creator, "burnToken: not have permission");
        require(isValidToken(tokenId), "burnToken: token id is invalid.");

        _burned[tokenId] = true;
        _balances[owner]--;

        //Reset approved if there is one
        if (_allowance[tokenId] != address(0)) {
            delete _allowance[tokenId];
        }
        
        uint256 oldIndex = _ownerTokenIndexes[tokenId];
        uint256 lastIndex = _ownerTokenIDs[owner].length - 1;
        string memory lastTokenId;
        if (oldIndex != lastIndex) {
            lastTokenId = _ownerTokenIDs[owner][lastIndex];
            _ownerTokenIDs[owner][oldIndex] = lastTokenId;
            _ownerTokenIndexes[lastTokenId] = oldIndex;
        }
        _ownerTokenIDs[owner].pop();
        delete _ownerTokenIndexes[tokenId];

        oldIndex = _tokenIndexes[tokenId];
        lastIndex = _tokenIDs.length - 1;
        if (oldIndex != lastIndex) {
            lastTokenId = _tokenIDs[lastIndex];
            _tokenIDs[oldIndex] = lastTokenId;
            _tokenIndexes[lastTokenId] = oldIndex;
        }
        _tokenIDs.pop();
        delete _tokenIndexes[tokenId];
        delete _tokenWeights[tokenId];
        delete _tokenTimestamps[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    
    /// @notice get list of token ids of an owner
    /// @dev throw if 'owner' is zero address
    /// @param owner address of owner
    /// @return list of token ids of owner
    function getTokenIDsOfOwner(address owner) external override view returns(string[] memory) {
        return _ownerTokenIDs[owner];
    }

    /// @notice get token weight
    /// @dev throw if token is not valid
    /// @param tokenId id of the token
    /// @return token weight
    function getTokenWeight(string memory tokenId) external override view returns(uint8) {
        require(isValidToken(tokenId), "getTokenWeight: token id is invalid.");

        return _tokenWeights[tokenId];
    }

    /// @notice get token timestamp
    /// @dev throw if token is not valid
    /// @param tokenId id of the token
    /// @return token timestamp
    function getTokenTimestamp(string memory tokenId) external override view returns(uint64) {
        require(isValidToken(tokenId), "getTokenTimestamp: token id is invalid.");

        return _tokenTimestamps[tokenId];
    }

    /// @notice change the token weight. only creator can change it
    /// @dev throw unless msg.sender is creator and token id is valid.
    /// @param tokenId id of token
    /// @param newWeight new value of token weight
    function updateTokenWeight(string memory tokenId, uint8 newWeight) public override whenNotPaused {
        require(msg.sender == _creator);
        require(isValidToken(tokenId), "updateTokenWeight: token id is invalid.");

        _tokenWeights[tokenId] = newWeight;
    }

    /// @notice change the token timestamp. only creator can change it
    /// @dev throw unless token id is valid.
    /// @param tokenId id of token
    /// @param newTimestamp new value of token timestamp
    function updateTokenTimestamp(string memory tokenId, uint64 newTimestamp) external override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands, updateTokenTimestamp: not authorised");
        require(isValidToken(tokenId), "updateTokenTimestamp: token id is invalid");

        _tokenTimestamps[tokenId] = newTimestamp;
    }

    /// @notice Checks if a given tokenId is valid
    /// @dev If adding the ability to burn tokens, this function will need to reflect that.
    /// @param tokenId The tokenId to check
    /// @return (bool) True if valid, False if not valid.
    function isValidToken(string memory tokenId) internal view returns (bool) {
        return _created[tokenId] && !_burned[tokenId];
    }
}