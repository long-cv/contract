// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC165.sol";
import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/ILands.sol";
import "./interfaces/IQuadKey.sol";
import "./libraries/SafeMath.sol";
import "./Pausable.sol";

contract QuadKey is ERC165, IQuadKey, Pausable {
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
    mapping(string => bool) internal _created; // token is created

    address _lands; // addres of lands
    string _baseLandId;

    /// @notice Contract constructor
    /// @param tokenName The name of token
    /// @param tokenSymbol The symbol of token
    constructor(address creator, string memory tokenName, string memory tokenSymbol, address lands, string memory baseLand) ERC165() {
        _creator = creator;

        _name = tokenName;
        _symbol = tokenSymbol;

        _lands = lands;
        _baseLandId = baseLand;
        //Add to ERC165 Interface Check
        _supportedInterfaces[
            this.balanceOf.selector ^
            this.isOwnerOf.selector ^
            bytes4(keccak256("safeTransferFrom(address,address,string,string,uint256,bytes)")) ^
            bytes4(keccak256("safeTransferFrom(address,address,string,string,uint256)")) ^
            this.transferFrom.selector ^
            this.approve.selector ^
            this.setApprovalForAll.selector ^
            this.getApproved.selector ^
            this.isApprovedForAll.selector ^
            this.totalSupply.selector ^
            this.tokenByIndex.selector ^
            this.tokenOfOwnerByIndex.selector ^
            this.tokenIndexOfOwnerById.selector ^
            this.name.selector ^
            this.symbol.selector ^
            bytes4(keccak256("issueToken(address,string,uint256)")) ^
            bytes4(keccak256("issueToken(address,string,string,uint256)")) ^
            this.getTokensOfOwner.selector
        ] = true;
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "setCreator: not creator");
        require(address(0) == creator, "setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address owner) external override view returns (uint256) {
        return _ownerTotalTokenBalance[owner];
    }

    /// @notice check the owner of an NFT
    /// @dev Throw if tokenId is not valid.
    /// @param owner address need to check
    /// @param tokenId The identifier for an NFT
    /// @return true if is owner, false if not
    function isOwnerOf(address owner, string memory tokenId) public override view returns (bool) {
        require(isValidToken(tokenId), "isOwnerOf: token is not valid.");

        return _isOwners[owner][tokenId];
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
    function safeTransferFrom(address from, address to, string memory tokenId, string memory landId, uint256 amount, bytes memory data) public override whenNotPaused {
        transferFrom(from, to, tokenId, landId, amount);

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
    function safeTransferFrom(address from, address to, string memory tokenId, string memory landId, uint256 amount) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, landId, amount, "");
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
    function transferFrom(address from, address to, string memory tokenId, string memory landId, uint256 amount) public override whenNotPaused {
        require(isOwnerOf(from, tokenId), "transferFrom: requrest for address not be an owner of token");
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "transferFrom: sender does not have permission");
        require(from != to, "transferFrom: source and destination address are same.");
        require(address(0) != to, "transferFrom: transfer to zero address.");
        require(isValidToken(tokenId), "transferFrom: token id is invalid");

        uint256 index = _ownerTokenIndexes[from][tokenId];
        _ownerTokens[from][index].balance = _ownerTokens[from][index].balance.sub(amount, "transferFrom: amount exceeds token balance");
        _ownerTotalTokenBalance[from] = _ownerTotalTokenBalance[from].sub(amount);

        _ownerTotalTokenBalance[to] = _ownerTotalTokenBalance[to].add(amount);
        if (!_isOwners[to][tokenId]) {
            _isOwners[to][tokenId] = true;
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

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param owner address of NFT owner
    /// @param spender address of new NFT controller
    /// @param tokenId The NFT to approve
    /// @param amount number of NFT to approve
    function approve(address owner, address spender, string memory tokenId, uint256 amount) public override whenNotPaused {
        require(isOwnerOf(owner, tokenId), "approve: requrest for address not be an owner of token");
        require(msg.sender == owner || _authorised[owner][msg.sender], "approve: sender does not have permission");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender][tokenId] = amount;
        emit Approval(owner, spender, tokenId, amount);
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

    /// @notice Get the approved amount of a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param owner address of owner of The NFT
    /// @param spender address of controler of The NFT
    /// @param tokenId The NFT id
    /// @return The approved amount for this NFT
    function getApproved(address owner, address spender, string memory tokenId) external override view returns (uint256) {
        require(isValidToken(tokenId), "getApproved: token id is invalid");

        return _allowances[owner][spender][tokenId];
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
        require(index < _tokenIDs.length);
        return _tokenIDs[index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index` is less than number of tokens owned or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param index A counter less than number of tokens owned
    /// @return The token identifier for the `index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address owner, uint256 index) external override view returns (QuadKeyInfo memory) {
        require(index < _ownerTokens[owner].length, "tokenOfOwnerByIndex: index is invalid");
        return _ownerTokens[owner][index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if token id is not valid or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param tokenId id of token
    /// @return The token identifier for the `index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenIndexOfOwnerById(address owner, string memory tokenId) external override view returns (uint256) {
        require(isOwnerOf(owner, tokenId), "tokenIndexOfOwnerById: requrest for address not be an owner of token");
        require(isValidToken(tokenId), "tokenIndexOfOwnerById: token id is invalid.");
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

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev check if token id is duplicated, or null or burned. Throw if msg.sender is not creator
    /// @param tokenId array of extra tokens to mint.
    /// @param amount number of token.
    function issueToken(address to, string memory tokenId, uint256 amount) public override whenNotPaused {
        issueToken(to, tokenId, _baseLandId, amount);
    }

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev check if token id is duplicated, or null or burned. Throw if msg.sender is not creator
    /// @param tokenId array of extra tokens to mint.
    /// @param amount number of token.
    function issueToken(address to, string memory tokenId, string memory landId, uint256 amount) public override whenNotPaused {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "issueToken: sender does not have permission.");
        require(address(0) != to, "issueToken: issue token for zero address");
        require(bytes(tokenId).length > 0, "issueToken: token id is null");

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

    /// @notice get list of token ids of an owner
    /// @dev throw if 'owner' is zero address
    /// @param owner address of owner
    /// @return list of token ids of owner
    function getTokensOfOwner(address owner) external override view returns(QuadKeyInfo[] memory) {
        return _ownerTokens[owner];
    }

    /// @notice Checks if a given tokenId is valid
    /// @dev If adding the ability to burn tokens, this function will need to reflect that.
    /// @param tokenId The tokenId to check
    /// @return (bool) True if valid, False if not valid.
    function isValidToken(string memory tokenId) public override view returns (bool) {
        return _created[tokenId];
    }
}