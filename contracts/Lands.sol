// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ILands.sol";
import "./libraries/SafeMath.sol";
import "./Pausable.sol";

contract Lands is ILands, Pausable {
    using SafeMath for uint256;

    address internal _creator;
    mapping(address => mapping(address => bool)) internal _authorised;

    string private _name;
    string private _symbol;
    mapping(address => mapping(string => mapping(uint16 => bool))) internal _isOwners;
    mapping(address => mapping(string => LandInfo[])) internal _ownerTokens; // array of tokenId of a owner
    mapping(address => mapping(string => mapping(uint16 => uint256))) internal _ownerTokenIndexes; // index of tokenId in array of tokenId of a owner

    uint16[] internal _tokenIDs; // array of tokenId
    mapping(uint16 => uint256) internal _tokenIndexes; // index of tokenId in array of tokenId
    mapping(uint16 => uint64) internal _interval; // interval that allow receiving the reward.
    uint256 _totalSupply; // total of all tokens supplied
    mapping(uint16 => bool) internal _created; // token is created

    constructor(address creator, string memory tokenName, string memory tokenSymbol, uint16[] memory initIDs, uint64[] memory initInterval) {
        _creator = creator;

        _name = tokenName;
        _symbol = tokenSymbol;

        for (uint i = 0; i < initIDs.length; i++) {
            _created[initIDs[i]] = true;
            _tokenIndexes[initIDs[i]] = i;
            _tokenIDs.push(initIDs[i]);
            _interval[initIDs[i]] = initInterval[i];
        }
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "Lands >> setCreator: not creator");
        require(address(0) != creator, "Lands >> setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    function getCreator() external view returns(address) {
        return _creator;
    }

    function isOwnerOf(address owner, string memory quadkey, uint16 tokenId) public override view returns (bool) {
        require(isValidToken(tokenId), "Lands >> isOwnerOf: token is not valid.");

        return _isOwners[owner][quadkey][tokenId];
    }

    function transferFrom(address from, address to, string memory quadkey, uint16 tokenId, uint176 amount) public override whenNotPaused returns(bool) {
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Lands >> transferFrom: sender does not have permission");
        require(from != to, "Lands >> transferFrom: source and destination address are same.");
        require(address(0) != to, "Lands >> transferFrom: transfer to zero address.");
        require(isValidToken(tokenId), "Lands >> transferFrom: token id is invalid");

        uint256 index = _ownerTokenIndexes[from][quadkey][tokenId];
        require(_ownerTokens[from][quadkey][index].amount >= amount, "Lands >> transferFrom: amount exceeds token amount");
        _ownerTokens[from][quadkey][index].amount -= amount;

        if (!_isOwners[to][quadkey][tokenId]) {
            _isOwners[to][quadkey][tokenId] = true;
            _ownerTokenIndexes[to][quadkey][tokenId] = _ownerTokens[to][quadkey].length;
            LandInfo memory land;
            land.id = tokenId;
            land.amount = amount;
            land.timestamp = uint64(block.timestamp % 2**64);
            _ownerTokens[to][quadkey].push(land);
        } else {
            index = _ownerTokenIndexes[to][quadkey][tokenId];
            _ownerTokens[to][quadkey][index].amount += amount;
            require(_ownerTokens[to][quadkey][index].amount >= amount, "Lands >> transferFrom: overflow");
            _ownerTokens[to][quadkey][index].timestamp = uint64(block.timestamp % 2**64);
        }

        emit Transfer(from, to, quadkey, tokenId, amount);
        return true;
    }

    function setApprovalForAll(address operator, bool approved) external override whenNotPaused returns(bool) {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
        return true;
    }

    function isApprovedForAll(address owner, address operator) external override view returns (bool) {
        return _authorised[owner][operator];
    }

    function totalSupply() external override view returns (uint256, uint256) {
        return (_tokenIDs.length, _totalSupply);
    }

    function tokenByIndex(uint256 index) external override view returns (uint16) {
        require(index < _tokenIDs.length, "Lands >> tokenByIndex: index is invalid");
        return _tokenIDs[index];
    }

    function tokenOfOwnerByIndex(address owner, string memory quadkey, uint256 index) external override view returns (LandInfo memory) {
        require(index < _ownerTokens[owner][quadkey].length, "Lands >> tokenOfOwnerByIndex: index is invalid");
        return _ownerTokens[owner][quadkey][index];
    }

    function tokenIndexOfOwnerById(address owner, string memory quadkey, uint16 tokenId) external override view returns (uint256) {
        require(isOwnerOf(owner, quadkey, tokenId), "Lands >> tokenIndexOfOwnerById: requrest for address not be an owner of token");
        require(isValidToken(tokenId), "Lands >> tokenIndexOfOwnerById: token id is invalid.");
        return _ownerTokenIndexes[owner][quadkey][tokenId];
    }

    function name() external override view returns (string memory __name) {
        __name = _name;
    }

    function symbol() external override view returns (string memory __symbol) {
        __symbol = _symbol;
    }

    function createToken(uint16 tokenId, uint64 interval) public override whenNotPaused returns(bool){
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Lands >> createToken: sender does not have permission");
        require(!_created[tokenId], "Lands >> createToken: token Id is created");

        _tokenIndexes[tokenId] = _tokenIDs.length;
        _tokenIDs.push(tokenId);
        _created[tokenId] = true;
        _interval[tokenId] = interval;

        return true;
    }

    function getTokenIDs() public override view returns(uint16[] memory) {
        return _tokenIDs;
    }

    function upgradeLand(address owner, string memory quadkey, uint16 fromLandId, uint16 toLandId, uint176 amount) external override whenNotPaused returns(bool) {
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Lands >> upgradeLand: sender does not have permission");
        require(isValidToken(fromLandId), "Lands >> upgradeLand: from token Id is invalid");
        require(isValidToken(toLandId), "Lands >> upgradeLand: to token Id is invalid");
        require(_interval[toLandId] < _interval[fromLandId], "Lands >> upgradeLand: not allow downgrading land");
        require(isOwnerOf(owner, quadkey, fromLandId), "Lands >> upgradeLand: not own land upgrading from yet");

        uint256 index = _ownerTokenIndexes[owner][quadkey][fromLandId];
        require(_ownerTokens[owner][quadkey][index].amount >= amount, "Lands >> upgradeLand: upgrade an amount greater than owning");
        _ownerTokens[owner][quadkey][index].amount -= amount;

        if (_isOwners[owner][quadkey][toLandId]) {
            index = _ownerTokenIndexes[owner][quadkey][toLandId];
            _ownerTokens[owner][quadkey][index].amount += amount;
            require(_ownerTokens[owner][quadkey][index].amount >= amount, "Lands >> upgradeLand: overflow");
            _ownerTokens[owner][quadkey][index].timestamp = uint64(block.timestamp % 2**64);
        } else {
            _isOwners[owner][quadkey][toLandId] = true;
            LandInfo memory token;
            token.id = toLandId;
            token.amount = amount;
            token.timestamp = uint64(block.timestamp % 2**64);
            _ownerTokenIndexes[owner][quadkey][toLandId] = _ownerTokens[owner][quadkey].length;
            _ownerTokens[owner][quadkey].push(token);
        }

        emit UpgradeLand(owner, quadkey, fromLandId, toLandId, amount);

        return true;
    }

    function issueToken(address to, string memory quadkey, uint16 tokenId, uint176 amount) public override whenNotPaused returns(bool) {
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Lands >> issueToken: sender does not have permission");
        require(address(0) != to, "Lands >> issueToken: issue token for zero address");
        require(isValidToken(tokenId), "Lands >> issueToken: token Id is invalid");

        _totalSupply = _totalSupply.add(amount);

        if (!_isOwners[to][quadkey][tokenId]) {
            _isOwners[to][quadkey][tokenId] = true;
            LandInfo memory token;
            token.id = tokenId;
            token.amount = amount;
            token.timestamp = uint64(block.timestamp % 2**64);
            _ownerTokenIndexes[to][quadkey][tokenId] = _ownerTokens[to][quadkey].length;
            _ownerTokens[to][quadkey].push(token);
        } else {
            uint256 index = _ownerTokenIndexes[to][quadkey][tokenId];
            _ownerTokens[to][quadkey][index].amount += amount;
            require(_ownerTokens[to][quadkey][index].amount >= amount, "Lands >> issueToken: overflow");
            _ownerTokens[to][quadkey][index].timestamp = uint64(block.timestamp % 2**64);
        }

        emit Transfer(msg.sender, to, quadkey, tokenId, amount);

        return true;
    }

    function getTokensOfOwner(address owner, string memory quadkey) external override view returns(LandInfo[] memory) {
        return _ownerTokens[owner][quadkey];
    }

    function getTokenTimestamp(address owner, string memory quadkey, uint16 tokenId) external view returns(uint64) {
        require(isValidToken(tokenId), "Lands >> getTokenTimestamp: token id is invalid.");
        require(isOwnerOf(owner, quadkey, tokenId), "Lands >> getTokenTimestamp: requrest for address not be an owner of token");

        uint256 index = _ownerTokenIndexes[owner][quadkey][tokenId];
        return _ownerTokens[owner][quadkey][index].timestamp;
    }

    function updateTokenTimestamp(address owner, string memory quadkey, uint16 tokenId, uint64 newTimestamp) external override whenNotPaused returns(bool) {
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Lands >> updateTokenTimestamp: sender does not have permission");
        require(isValidToken(tokenId), "Lands >> updateTokenTimestamp: token id is invalid");
        require(isOwnerOf(owner, quadkey, tokenId), "Lands >> updateTokenTimestamp: requrest for address not be an owner of token");

        uint256 index = _ownerTokenIndexes[owner][quadkey][tokenId];
        _ownerTokens[owner][quadkey][index].timestamp = newTimestamp;

        return true;
    }

    function getTokenInterval(uint16 tokenId) external override view returns(uint64) {
        require(isValidToken(tokenId), "Lands >> getTokenInterval: token id is invalid");

        return _interval[tokenId];
    }

    function setTokenInterval(uint16 tokenId, uint64 interval) public {
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Lands >> setTokenInterval: not permission");
        require(interval > 0, "Lands >> setTokenInterval: interval is negative");

        _interval[tokenId] = interval;
    }

    function isValidToken(uint16 tokenId) internal view returns (bool) {
        return _created[tokenId];
    }
}