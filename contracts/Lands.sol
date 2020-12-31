// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/ILands.sol";
import "./libraries/SafeMath.sol";
import "./Pausable.sol";

contract Lands is ILands, Pausable {
    using SafeMath for uint256;

    address internal _creator;
    mapping(address => mapping(address => bool)) internal _authorised;

    string private _name;
    string private _symbol;
    mapping(address => mapping(string => mapping(string => bool))) internal _isOwners;
    mapping(address => mapping(string => Tokens[])) internal _ownerTokens; // array of tokenId of a owner
    mapping(address => mapping(string => mapping(string => uint256))) internal _ownerTokenIndexes; // index of tokenId in array of tokenId of a owner

    string[] internal _tokenIDs; // array of tokenId
    mapping(string => uint256) internal _tokenIndexes; // index of tokenId in array of tokenId
    mapping(string => uint64) internal _interval; // interval that allow receiving the reward.
    Supplies _totalSupply; // total of all tokens supplied
    mapping(string => bool) internal _created; // token is created

    /// @notice Contract constructor
    /// @param tokenName The name of token
    /// @param tokenSymbol The symbol of token
    constructor(address creator, string memory tokenName, string memory tokenSymbol, string[] memory initIDs, uint64[] memory initInterval) {
        _creator = creator;

        _name = tokenName;
        _symbol = tokenSymbol;

        for (uint i = 0; i < initIDs.length; i++) {
            _created[initIDs[i]] = true;
            _tokenIndexes[initIDs[i]] = i;
            _tokenIDs.push(initIDs[i]);
            _totalSupply.totalIdSupplies = _totalSupply.totalIdSupplies.add(1);
            _interval[initIDs[i]] = initInterval[i];
        }
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "Lands >> setCreator: not creator");
        require(address(0) != creator, "Lands >> setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    /// @notice check the owner of an NFT
    /// @dev Throw if tokenId is not valid.
    /// @param owner address need to check
    /// @param tokenId The identifier for an NFT
    /// @return true if is owner, false if not
    function isOwnerOf(address owner, string memory quadkey, string memory tokenId) public override view returns (bool) {
        require(isValidToken(tokenId), "Lands >> isOwnerOf: token is not valid.");

        return _isOwners[owner][quadkey][tokenId];
    }

    /// @notice Transfers number of an NFT from one address to another address
    /// @dev When transfer is complete, this function
    ///  checks if `to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,string,uint256,bytes)"))`.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param amount The amount of NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `to`
    function safeTransferFrom(address from, address to, string memory quadkey, string memory tokenId, uint256 amount, bytes memory data) public override whenNotPaused {
        transferFrom(from, to, quadkey, tokenId, amount);

        //Get size of "to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(to)
        }

        if (size > 0) {
            IERC721TokenReceiver receiver = IERC721TokenReceiver(to);
            require(receiver.onERC721Received(msg.sender, from, tokenId, amount, data) == bytes4(keccak256("onERC721Received(address,address,string,uint256,bytes)")));
        }
    }

    /// @notice Transfers a number of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param amount The amount of NFT to transfer
    function safeTransferFrom(address from, address to, string memory quadkey, string memory tokenId, uint256 amount) public override whenNotPaused {
        safeTransferFrom(from, to, quadkey, tokenId, amount, "");
    }

    /// @notice Transfer a number of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. Throws if the NFT balance is less than `amount`
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param amount The amount of NFT to transfer
    function transferFrom(address from, address to, string memory quadkey, string memory tokenId, uint256 amount) public override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands >> transferFrom: sender does not have permission");
        require(from != to, "Lands >> transferFrom: source and destination address are same.");
        require(address(0) != to, "Lands >> transferFrom: transfer to zero address.");
        require(isValidToken(tokenId), "Lands >> transferFrom: token id is invalid");

        uint256 index = _ownerTokenIndexes[from][quadkey][tokenId];
        _ownerTokens[from][quadkey][index].balance = _ownerTokens[from][quadkey][index].balance.sub(amount, "transferFrom: amount exceeds token balance");

        if (!_isOwners[to][quadkey][tokenId]) {
            _isOwners[to][quadkey][tokenId] = true;
            _ownerTokenIndexes[to][quadkey][tokenId] = _ownerTokens[to][quadkey].length;
            Tokens memory land;
            land.id = tokenId;
            land.balance = amount;
            land.timestamp = uint64(block.timestamp % 2**64);
            _ownerTokens[to][quadkey].push(land);
        } else {
            index = _ownerTokenIndexes[to][quadkey][tokenId];
            _ownerTokens[to][quadkey][index].balance = _ownerTokens[to][quadkey][index].balance.add(amount);
            _ownerTokens[to][quadkey][index].timestamp = uint64(block.timestamp % 2**64);
        }

        emit Transfer(from, to, quadkey, tokenId, amount);
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
    function totalSupply() external override view returns (Supplies memory) {
        return _totalSupply;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `index` >= `totalSupply()`.
    /// @param index A counter less than `totalSupply()`
    /// @return The token identifier for the `index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 index) external override view returns (string memory) {
        require(index < _tokenIDs.length, "Lands >> tokenByIndex: index is invalid");
        return _tokenIDs[index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index` is less than number of tokens owned or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param index A counter less than number of tokens owned
    /// @return The token identifier for the `index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address owner, string memory quadkey, uint256 index) external override view returns (Tokens memory) {
        require(index < _ownerTokens[owner][quadkey].length, "Lands >> tokenOfOwnerByIndex: index is invalid");
        return _ownerTokens[owner][quadkey][index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if token id is not valid or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param tokenId id of token
    /// @return The token identifier for the `index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenIndexOfOwnerById(address owner, string memory quadkey, string memory tokenId) external override view returns (uint256) {
        require(isOwnerOf(owner, quadkey, tokenId), "Lands >> tokenIndexOfOwnerById: requrest for address not be an owner of token");
        require(isValidToken(tokenId), "Lands >> tokenIndexOfOwnerById: token id is invalid.");
        return _ownerTokenIndexes[owner][quadkey][tokenId];
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external override view returns (string memory __name) {
        __name = _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external override view returns (string memory __symbol) {
        __symbol = _symbol;
    }

    function createToken(string memory tokenId, uint64 interval) public override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands >> createToken: sender does not have permission");
        require(bytes(tokenId).length > 0, "Lands >> createToken: token id is null");
        require(!_created[tokenId], "Lands >> createToken: token Id is created");

        uint oldLength = _tokenIDs.length;
        _tokenIDs.push(tokenId);
        uint i = 0;
        while (i < oldLength) {
            if (_interval[_tokenIDs[i]] > interval) {
                break;
            }
            i++;
        }
        if (i < oldLength) {
            for (uint j = oldLength; j > i; j--) {
                _tokenIDs[j] = _tokenIDs[j - 1];
                _tokenIndexes[_tokenIDs[j]] = j;
            }
            _tokenIDs[i] = tokenId;
        }
        _created[tokenId] = true;
        _tokenIndexes[tokenId] = i;
        _interval[tokenId] = interval;
        _totalSupply.totalIdSupplies = _totalSupply.totalIdSupplies.add(1);
    }

    function getTokenIDs() public override view returns(string[] memory) {
        return _tokenIDs;
    }

    function upgradeLand(address owner, string memory quadkey, string memory fromLandId, string memory toLandId, uint256 amount) external override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands >> upgradeLand: sender does not have permission");
        require(isValidToken(fromLandId), "Lands >> upgradeLand: from token Id is invalid");
        require(isValidToken(toLandId), "Lands >> upgradeLand: to token Id is invalid");
        require(_interval[toLandId] < _interval[fromLandId], "Lands >> upgradeLand: not allow downgrading land");
        require(isOwnerOf(owner, quadkey, fromLandId), "Lands >> upgradeLand: not own land upgrading from yet");

        uint256 index = _ownerTokenIndexes[owner][quadkey][fromLandId];
        _ownerTokens[owner][quadkey][index].balance = _ownerTokens[owner][quadkey][index].balance.sub(amount, "Lands >> upgradeLand: upgrade an amount greater than owning");

        if (_isOwners[owner][quadkey][toLandId]) {
            index = _ownerTokenIndexes[owner][quadkey][toLandId];
            _ownerTokens[owner][quadkey][index].balance = _ownerTokens[owner][quadkey][index].balance.add(amount);
            _ownerTokens[owner][quadkey][index].timestamp = uint64(block.timestamp % 2**64);
        } else {
            _isOwners[owner][quadkey][toLandId] = true;
            Tokens memory token;
            token.id = toLandId;
            token.balance = amount;
            token.timestamp = uint64(block.timestamp % 2**64);
            _ownerTokenIndexes[owner][quadkey][toLandId] = _ownerTokens[owner][quadkey].length;
            _ownerTokens[owner][quadkey].push(token);
        }

        emit UpgradeLand(owner, quadkey, fromLandId, toLandId, amount);
    }

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev check if token id is duplicated, or null or burned. Throw if msg.sender is not creator
    /// @param tokenId array of extra tokens to mint.
    /// @param amount number of token.
    function issueToken(address to, string memory quadkey, string memory tokenId, uint256 amount) public override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands >> issueToken: sender does not have permission");
        require(address(0) != to, "Lands >> issueToken: issue token for zero address");
        require(bytes(tokenId).length > 0, "Lands >> issueToken: token id is null");
        require(isValidToken(tokenId), "Lands >> issueToken: token Id is invalid");

        _totalSupply.totalTokenSupples = _totalSupply.totalTokenSupples.add(amount);

        if (!_isOwners[to][quadkey][tokenId]) {
            _isOwners[to][quadkey][tokenId] = true;
            Tokens memory token;
            token.id = tokenId;
            token.balance = amount;
            token.timestamp = uint64(block.timestamp % 2**64);
            _ownerTokenIndexes[to][quadkey][tokenId] = _ownerTokens[to][quadkey].length;
            _ownerTokens[to][quadkey].push(token);
        } else {
            uint256 index = _ownerTokenIndexes[to][quadkey][tokenId];
            _ownerTokens[to][quadkey][index].balance = _ownerTokens[to][quadkey][index].balance.add(amount);
            _ownerTokens[to][quadkey][index].timestamp = uint64(block.timestamp % 2**64);
        }

        emit Transfer(msg.sender, to, quadkey, tokenId, amount);
    }

    /// @notice get list of token ids of an owner
    /// @dev throw if 'owner' is zero address
    /// @param owner address of owner
    /// @return list of token ids of owner
    function getTokensOfOwner(address owner, string memory quadkey) external override view returns(Tokens[] memory) {
        return _ownerTokens[owner][quadkey];
    }

    /// @notice get token timestamp
    /// @dev throw if token is not valid
    /// @param tokenId id of the token
    /// @return token timestamp
    function getTokenTimestamp(address owner, string memory quadkey, string memory tokenId) external view returns(uint64) {
        require(isValidToken(tokenId), "Lands >> getTokenTimestamp: token id is invalid.");
        require(isOwnerOf(owner, quadkey, tokenId), "Lands >> getTokenTimestamp: requrest for address not be an owner of token");

        uint256 index = _ownerTokenIndexes[owner][quadkey][tokenId];
        return _ownerTokens[owner][quadkey][index].timestamp;
    }

    /// @notice change the token timestamp. only creator or operator of creator can change it
    /// @dev throw unless token id is valid.
    /// @param tokenId id of token
    /// @param newTimestamp new value of token timestamp
    function updateTokenTimestamp(address owner, string memory quadkey, string memory tokenId, uint64 newTimestamp) external override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands >> updateTokenTimestamp: sender does not have permission");
        require(isValidToken(tokenId), "Lands >> updateTokenTimestamp: token id is invalid");
        require(isOwnerOf(owner, quadkey, tokenId), "Lands >> updateTokenTimestamp: requrest for address not be an owner of token");

        uint256 index = _ownerTokenIndexes[owner][quadkey][tokenId];
        _ownerTokens[owner][quadkey][index].timestamp = newTimestamp;
    }

    function getTokenInterval(string memory tokenId) external override view returns(uint64) {
        require(isValidToken(tokenId), "Lands >> getTokenInterval: token id is invalid");

        return _interval[tokenId];
    }

    function setTokenInterval(string memory tokenId, uint64 interval) public {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Lands >> setTokenInterval: not permission");
        require(interval > 0, "Lands >> setTokenInterval: interval is negative");

        _interval[tokenId] = interval;
    }

    /// @notice Checks if a given tokenId is valid
    /// @dev If adding the ability to burn tokens, this function will need to reflect that.
    /// @param tokenId The tokenId to check
    /// @return (bool) True if valid, False if not valid.
    function isValidToken(string memory tokenId) internal view returns (bool) {
        return _created[tokenId];
    }
}