// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ILandType.sol";
import "./interfaces/ILand.sol";
import "./libraries/SafeMath.sol";
import "./Pausable.sol";

contract Land is ILand, Pausable {
    using SafeMath for uint256;

    address internal _creator;
    
    mapping(address => mapping(address => mapping(string => uint256))) internal _allowances;
    mapping(address => mapping(address => bool)) internal _authorised;

    string private _name;
    string private _symbol;

    mapping(address => string[]) internal _ownerTokens; // array of tokenId of a owner
    mapping(address => mapping(string => uint256)) internal _ownerTokenIndexes; // index of tokenId in array of tokenId of a owner
    mapping(address => mapping(string => uint256)) internal _ownerTokenAmount;

    string[] internal _tokenIDs; // array of tokenId
    mapping(string => uint256) internal _tokenIndexes; // index of tokenId in array of tokenId
    uint256 _totalSupply; // total of all tokens supplied
    mapping(string => bool) internal _created; // token is created

    address _landType; // addres of land type
    uint16 _baseLandType;

    constructor(address creator, string memory tokenName, string memory tokenSymbol, address landType, uint16 baseLand) {
        _creator = creator;

        _name = tokenName;
        _symbol = tokenSymbol;

        _landType = landType;
        _baseLandType = baseLand;
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "Land >> setCreator: not creator");
        require(address(0) != creator, "Land >> setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    function getCreator() external view returns(address) {
        return _creator;
    }

    function balanceOf(address owner) external override view returns (uint256) {
        string[] memory quadkeys = _ownerTokens[owner];
        uint256 amount;
        for (uint i = 0; i < quadkeys.length; i++) {
            amount += _ownerTokenAmount[owner][quadkeys[i]];
        }

        return amount;
    }

    function isOwnerOf(address owner, string memory tokenId) public override view returns (bool) {
        require(isValidToken(tokenId), "Land >> isOwnerOf: token is not valid.");

        return _ownerTokenAmount[owner][tokenId] > 0;
    }

    function transferFrom(address from, address to, string memory tokenId, uint16 landId, uint176 amount) public override whenNotPaused returns(bool) {
        require(isOwnerOf(from, tokenId), "Land >> transferFrom: requrest for address not be an owner of token");
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Land >> transferFrom: sender does not have permission");
        require(from != to, "Land >> transferFrom: source and destination address are same.");
        require(address(0) != to, "Land >> transferFrom: transfer to zero address.");
        require(isValidToken(tokenId), "Land >> transferFrom: token id is invalid");

        _ownerTokenAmount[from][tokenId] = _ownerTokenAmount[from][tokenId].sub(amount, "Land >> transferFrom: amount exceeds token amount");

        if (_ownerTokenAmount[from][tokenId] == 0) {
            uint256 index = _ownerTokenIndexes[from][tokenId];
            uint256 lastIndex = _ownerTokens[from].length - 1;
            if (index != lastIndex) {
                string memory lastId = _ownerTokens[from][lastIndex];
                _ownerTokens[from][index] = lastId;
                _ownerTokenIndexes[from][lastId] = index;
            }
            _ownerTokens[from].pop();
        }

        if (_ownerTokenAmount[to][tokenId] == 0) {
            _ownerTokenIndexes[to][tokenId] = _ownerTokens[to].length;
            _ownerTokens[to].push(tokenId);
            _ownerTokenAmount[to][tokenId] = amount;
        } else {
            _ownerTokenAmount[to][tokenId] = _ownerTokenAmount[to][tokenId].add(amount);
        }

        ILandType(_landType).transferFrom(from, to, tokenId, landId, amount);

        emit Transfer(from, to, tokenId, amount);

        return true;
    }

    function approve(address owner, address spender, string memory tokenId, uint256 amount) public override whenNotPaused {
        require(isOwnerOf(owner, tokenId), "Land >> approve: requrest for address not be an owner of token");
        require(msg.sender == owner || _authorised[owner][msg.sender], "Land >> approve: sender does not have permission");
        require(spender != address(0), "Land >> approve to the zero address");

        _allowances[owner][spender][tokenId] = amount;
        emit Approval(owner, spender, tokenId, amount);
    }

    function setApprovalForAll(address operator, bool approved) external override whenNotPaused {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
    }

    function getApproved(address owner, address spender, string memory tokenId) external override view returns (uint256) {
        require(isValidToken(tokenId), "Land >> getApproved: token id is invalid");

        return _allowances[owner][spender][tokenId];
    }

    function isApprovedForAll(address owner, address operator) external override view returns (bool) {
        return _authorised[owner][operator];
    }

    function totalSupply() external override view returns (uint256, uint256) {
        return (_tokenIDs.length, _totalSupply);
    }

    function tokenByIndex(uint256 index) external override view returns (string memory) {
        require(index < _tokenIDs.length, "Land >> tokenByIndex: index is invalid");
        return _tokenIDs[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external override view returns (string memory) {
        require(index < _ownerTokens[owner].length, "Land >> tokenOfOwnerByIndex: index is invalid");
        return _ownerTokens[owner][index];
    }

    function tokenIndexOfOwnerById(address owner, string memory tokenId) external override view returns (uint256) {
        require(isOwnerOf(owner, tokenId), "Land >> tokenIndexOfOwnerById: requrest for address not be an owner of token");
        require(isValidToken(tokenId), "Land >> tokenIndexOfOwnerById: token id is invalid.");
        return _ownerTokenIndexes[owner][tokenId];
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external override view returns (string memory __name) {
        __name = _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external override view returns (string memory __symbol) {
        __symbol = _symbol;
    }

    function issueToken(address to, string memory tokenId, uint176 amount) public override whenNotPaused returns(bool) {
        return issueToken(to, tokenId, _baseLandType, amount);
    }

    function issueToken(address to, string memory tokenId, uint16 landId, uint176 amount) public override whenNotPaused returns(bool) {
        require(_authorised[_creator][msg.sender] || msg.sender == _creator, "Land >> issueToken: sender does not have permission.");
        require(address(0) != to, "Land >> issueToken: issue token for zero address");
        require(bytes(tokenId).length > 0, "Land >> issueToken: token id is null");

        if (!_created[tokenId]) {
            _created[tokenId] = true;
            _tokenIndexes[tokenId] = _tokenIDs.length;
            _tokenIDs.push(tokenId);
        }
        _totalSupply = _totalSupply.add(amount);

        if (_ownerTokenAmount[to][tokenId] == 0) {
            _ownerTokenIndexes[to][tokenId] = _ownerTokens[to].length;
            _ownerTokens[to].push(tokenId);
            _ownerTokenAmount[to][tokenId] = amount;
        } else {
            _ownerTokenAmount[to][tokenId] = _ownerTokenAmount[to][tokenId].add(amount);
        }

        ILandType(_landType).issueToken(to, tokenId, landId, amount);

        emit Transfer(msg.sender, to, tokenId, amount);

        return true;
    }

    function getTokensOfOwner(address owner) external override view returns(string[] memory) {
        return _ownerTokens[owner];
    }

    function getTokenAmountOfOwner(address owner, string memory tokenId) external override view returns(uint256) {
        return _ownerTokenAmount[owner][tokenId];
    }

    function isValidToken(string memory tokenId) public override view returns (bool) {
        return _created[tokenId];
    }
}