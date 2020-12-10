/**
 *Submitted for verification at Etherscan.io on 2019-11-28
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./ERC20Mintable.sol";
import "./Pausable.sol";

contract Time is ERC20Mintable, Pausable {

    mapping(address => mapping(address => bool)) internal _authorised;
    event ApprovalForAll(address indexed sender, address indexed operator, bool approved);

    constructor(uint _totalSupply, string memory _name, string memory _symbol, uint8 _decimals) ERC20Mintable(_name, _symbol, _decimals) {
        uint256 totalSupply = _totalSupply * (10 ** uint256(decimals()));
        mint(_msgSender(), totalSupply);       
    }

    function transfer(address to, uint256 value) public override whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override whenNotPaused returns (bool) {
        uint256 allowances = allowance(from, _msgSender());
        require(_msgSender() == from || isApprovedForAll(from, _msgSender()) || allowances >= value, "transferFrom: sender does not have permission");
        _transfer(from, to, value);
        if (_msgSender() != from && !isApprovedForAll(from, _msgSender())) _approve(from, _msgSender(), allowances - value);
        return true;
    }

    function approve(address spender, uint256 value) public override whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external whenNotPaused {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[_msgSender()][operator] = approved;
    }
    /// @notice Query if an address is an authorized operator for another address
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _authorised[owner][operator];
    }
}