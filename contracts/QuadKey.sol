// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ILands.sol";
import "./interfaces/IQuadkey.sol";
import "./libraries/SafeMath.sol";
import "./Pausable.sol";

contract Quadkey is IQuadkey, Pausable {
    using SafeMath for uint256;

    address internal _creator;
    
    mapping(address => mapping(string => bool)) internal _isOwners;
    mapping(address => mapping(address => mapping(string => uint256))) internal _allowances;
    mapping(address => mapping(address => bool)) internal _authorised;

    string private _name;
    string private _symbol;

    mapping(address => QuadKeyInfo[]) internal _ownerTokens; // array of tokenId of a owner
    mapping(address => mapping(string => uint256)) internal _ownerTokenIndexes; // index of tokenId in array of tokenId of a owner
    mapping(address => uint256) internal _ownerTotalTokenBalance; // total of all tokens owned

    string[] internal _tokenIDs; // array of tokenId
    mapping(string => uint256) internal _tokenIndexes; // index of tokenId in array of tokenId
    Supplies _totalSupply; // total of all tokens supplied
    mapping(string => address[]) internal _owners; // list of owner of land
    mapping(string => bool) internal _created; // token is created

    address _lands; // addres of lands
    uint16 _baseLandId;

    /// @notice Contract constructor
    /// @param tokenName The name of token
    /// @param tokenSymbol The symbol of token
    constructor(address creator, string memory tokenName, string memory tokenSymbol, address lands, uint16 baseLand) {
        _creator = creator;

        _name = tokenName;
        _symbol = tokenSymbol;

        _lands = lands;
        _baseLandId = baseLand;
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "Quadkey >> setCreator: not creator");
        require(address(0) != creator, "Quadkey >> setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    function balanceOf(address owner) external override view returns (uint256) {
        return _ownerTotalTokenBalance[owner];
    }

    function isOwnerOf(address owner, string memory tokenId) public override view returns (bool) {
        require(isValidToken(tokenId), "Quadkey >> isOwnerOf: token is not valid.");

        return _isOwners[owner][tokenId];
    }

    function ownerOf(string memory tokenId) external override view returns (address[] memory) {
        require(isValidToken(tokenId), "Quadkey >> ownerOf: token is not valid.");

        return _owners[tokenId];
    }

    function transferFrom(address from, address to, string memory tokenId, uint16 landId, uint176 amount) public override whenNotPaused {
        require(isOwnerOf(from, tokenId), "Quadkey >> transferFrom: requrest for address not be an owner of token");
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Quadkey >> transferFrom: sender does not have permission");
        require(from != to, "Quadkey >> transferFrom: source and destination address are same.");
        require(address(0) != to, "Quadkey >> transferFrom: transfer to zero address.");
        require(isValidToken(tokenId), "Quadkey >> transferFrom: token id is invalid");

        uint256 index = _ownerTokenIndexes[from][tokenId];
        _ownerTokens[from][index].balance = _ownerTokens[from][index].balance.sub(amount, "Quadkey >> transferFrom: amount exceeds token balance");
        _ownerTotalTokenBalance[from] = _ownerTotalTokenBalance[from].sub(amount);

        _ownerTotalTokenBalance[to] = _ownerTotalTokenBalance[to].add(amount);
        if (!_isOwners[to][tokenId]) {
            _isOwners[to][tokenId] = true;
            _owners[tokenId].push(to);
            _ownerTokenIndexes[to][tokenId] = _ownerTokens[to].length;
            QuadKeyInfo memory land;
            land.id = tokenId;
            land.balance = amount;
            _ownerTokens[to].push(land);
        } else {
            index = _ownerTokenIndexes[to][tokenId];
            _ownerTokens[to][index].balance = _ownerTokens[to][index].balance.add(amount);
        }

        ILands(_lands).transferFrom(from, to, tokenId, landId, amount);

        emit Transfer(from, to, tokenId, amount);
    }

    function approve(address owner, address spender, string memory tokenId, uint256 amount) public override whenNotPaused {
        require(isOwnerOf(owner, tokenId), "Quadkey >> approve: requrest for address not be an owner of token");
        require(msg.sender == owner || _authorised[owner][msg.sender], "Quadkey >> approve: sender does not have permission");
        require(spender != address(0), "Quadkey >> approve to the zero address");

        _allowances[owner][spender][tokenId] = amount;
        emit Approval(owner, spender, tokenId, amount);
    }

    function setApprovalForAll(address operator, bool approved) external override whenNotPaused {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
    }

    function getApproved(address owner, address spender, string memory tokenId) external override view returns (uint256) {
        require(isValidToken(tokenId), "Quadkey >> getApproved: token id is invalid");

        return _allowances[owner][spender][tokenId];
    }

    function isApprovedForAll(address owner, address operator) external override view returns (bool) {
        return _authorised[owner][operator];
    }

    function totalSupply() external override view returns (Supplies memory) {
        return _totalSupply;
    }

    function tokenByIndex(uint256 index) external override view returns (string memory) {
        require(index < _tokenIDs.length, "Quadkey >> tokenByIndex: index is invalid");
        return _tokenIDs[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external override view returns (QuadKeyInfo memory) {
        require(index < _ownerTokens[owner].length, "Quadkey >> tokenOfOwnerByIndex: index is invalid");
        return _ownerTokens[owner][index];
    }

    function tokenIndexOfOwnerById(address owner, string memory tokenId) external override view returns (uint256) {
        require(isOwnerOf(owner, tokenId), "Quadkey >> tokenIndexOfOwnerById: requrest for address not be an owner of token");
        require(isValidToken(tokenId), "Quadkey >> tokenIndexOfOwnerById: token id is invalid.");
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

    function issueToken(address to, string memory tokenId, uint176 amount) public override whenNotPaused {
        issueToken(to, tokenId, _baseLandId, amount);
    }

    function issueToken(address to, string memory tokenId, uint16 landId, uint176 amount) public override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Quadkey >> issueToken: sender does not have permission.");
        require(address(0) != to, "Quadkey >> issueToken: issue token for zero address");
        require(bytes(tokenId).length > 0, "Quadkey >> issueToken: token id is null");

        if (!_created[tokenId]) {
            _created[tokenId] = true;
            _tokenIndexes[tokenId] = _tokenIDs.length;
            _tokenIDs.push(tokenId);
            _totalSupply.totalIdSupplies = _totalSupply.totalIdSupplies.add(1);
        }
        _totalSupply.totalTokenSupples = _totalSupply.totalTokenSupples.add(amount);

        _ownerTotalTokenBalance[to] = _ownerTotalTokenBalance[to].add(amount);
        if (!_isOwners[to][tokenId]) {
            _isOwners[to][tokenId] = true;
            _owners[tokenId].push(to);
            QuadKeyInfo memory token;
            token.id = tokenId;
            token.balance = amount;
            _ownerTokenIndexes[to][tokenId] = _ownerTokens[to].length;
            _ownerTokens[to].push(token);
        } else {
            uint256 index = _ownerTokenIndexes[to][tokenId];
            _ownerTokens[to][index].balance = _ownerTokens[to][index].balance.add(amount);
        }

        ILands(_lands).issueToken(to, tokenId, landId, amount);

        emit Transfer(msg.sender, to, tokenId, amount);
    }

    function getTokensOfOwner(address owner) external override view returns(QuadKeyInfo[] memory) {
        return _ownerTokens[owner];
    }

    function isValidToken(string memory tokenId) public override view returns (bool) {
        return _created[tokenId];
    }
}