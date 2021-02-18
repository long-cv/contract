// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "../struct/struct.sol";

interface ITime is IERC20 {
    event ApprovalForAll(address indexed sender, address indexed operator, bool approved);
    
    event AddLockType(uint8 lockType, uint120 lockAmount);

    event UpdateLockType(uint8 lockType, uint120 lockAmount);

    event SetAccountLockType(address indexed account, uint8 lockType);

    event UpdateAccountLockType(address account, uint8 lockType);

    event ChangeCreator(address indexed oldCreator, address indexed newCreator);

    event ChangeSupplier(address indexed oldSupplier, address indexed newNewSupplier);

    function setApprovalForAll(address operator, bool approved) external;
   
    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function isValidLockType(uint8 lockType) external view returns(bool);

    function addLockType(uint8 lockType, uint120 lockAmount) external returns(bool);

    function updateLockType(uint8 lockType, uint120 lockAmount) external returns(bool);

    function getLockTypes() external view returns(uint8[] memory, uint120[] memory);

    function getLockTypeAmount(uint8 lockType) external view returns(uint120);

    function isLockActivate(address account) external view returns(bool);

    function setAccountLockType(address account, uint8 lockType) external returns(bool);

    function updateAccountLockType(address account, uint8 lockType) external returns(bool);

    function getAccountLockType(address account) external view returns(LockInfo memory);

    function getQuotaAmountLeft(address account) external view returns(bool, uint120, uint120, uint64);

    function transferFromOperator(address recipient, uint256 amount) external returns(bool);

    function transferFromSupplier(address recipient, uint256 amount) external returns(bool);

    function transferToSupplier(address sender, uint120 amount) external returns(bool);
}
