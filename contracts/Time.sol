/**
 *Submitted for verification at Etherscan.io on 2019-11-28
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";
import "./Pausable.sol";

contract Time is ERC20Detailed, ERC20Mintable, Pausable {
    constructor(uint _totalSupply, string memory _name, string memory _symbol, uint8 _decimals) ERC20Detailed(_name, _symbol, _decimals) {
        uint256 totalSupply = _totalSupply * (10 ** uint256(decimals()));
        mint(_msgSender(), totalSupply);       
    }

    function transfer(address to, uint256 value) public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public virtual override whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}