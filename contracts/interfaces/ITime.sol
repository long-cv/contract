// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "../struct/struct.sol";

interface ITime is IERC20 {
    event ApprovalForAll(address indexed sender, address indexed operator, bool approved);
    
    event AddLockType(string lockType, uint256 lockAmount);

    event SetAccountLockType(address indexed account, string userId, string lockType);

    event UpdateAccountLockType(address account, string lockType);

    function mint(address account, uint256 amount) external returns(bool);

    function setApprovalForAll(address operator, bool approved) external;
   
    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function isValidLockType(string memory lockType) external view returns(bool);

    function addLockType(string memory lockType, uint256 lockAmount) external returns(bool);

    function getLockTypes() external view returns(string[] memory);

    function getLockTypeAmount(string memory lockType) external view returns(uint256);

    function isLockActivate(address account) external view returns(bool);

    function setAccountLockType(address account, string memory userId, string memory lockType) external returns(bool);

    function updateAccountLockType(address account, string memory lockType) external returns(bool);

    function updateUserIdLockType(address account, string memory userId) external returns(bool);

    function getAccountLockType(address account) external view returns(LockInfo memory);

    function getQuotaAmountLeft(address account) external view returns(bool, uint256, uint64);
}
