/**
 *Submitted for verification at Etherscan.io on 2019-11-28
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./MinterRole.sol";
import "./Pausable.sol";
import "./interfaces/ITime.sol";

contract Time is ITime, MinterRole, Pausable {
    using SafeMath for uint256;
    
    address _creator;

    string private _name;
    
    string private _symbol;
    
    uint8 private _decimals;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => mapping(address => bool)) internal _authorised;

    uint256 private _totalSupply;

    mapping(address => LockInfo) _accountLockInfo;

    mapping(string => uint256) _lockTypeTable;

    string[] _lockTypes;

    uint64 _lockTypeInterval; 

    mapping(string => bool) _lockTypeCreated;

    constructor(address minter, uint supply, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, string memory ulimitedLockType, uint64 lockTypeInterval) {
        _creator = minter;
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        uint256 tokenSupply = supply * (10 ** uint256(_decimals));
        mint(minter, tokenSupply);
        _lockTypeTable[ulimitedLockType] = 2**256 - 1; // MAX_UINT256
        _lockTypes.push(ulimitedLockType);
        _lockTypeCreated[ulimitedLockType] = true;
        _lockTypeInterval = lockTypeInterval;
    }

    function setCreator(address creator) external {
        require(_msgSender() == _creator, "Time >> setCreator: sender does not have permission");
        require(address(0) != creator, "Time >> setCreator: creator can not be zero address");

        _creator = creator;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Time >> transfer from the zero address");
        require(recipient != address(0), "Time >> transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "Time >> transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Time >> mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Time >> approve from the zero address");
        require(spender != address(0), "Time >> approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return transferFrom(_msgSender(), recipient, amount);
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 allowances = allowance(sender, _msgSender());
        require(_msgSender() == sender || isApprovedForAll(sender, _msgSender()) || allowances >= amount, "Time >> transferFrom: sender does not have permission");
        require(isLockActivate(sender), "Time >> transferFrom: lock type was not set");

        (bool unlimited, uint256 quotaLeft, uint64 milestonePassed) = computeQuotaAmountLeft(_accountLockInfo[sender]);
        if (!unlimited) {
            require(quotaLeft >= amount, "Time >> transferFrom: quota left is not enough");

            if (_accountLockInfo[sender].milestonePassed < milestonePassed) {
                _accountLockInfo[sender].milestonePassed = milestonePassed;
                _accountLockInfo[sender].totalSpent = amount;
            } else {
                _accountLockInfo[sender].totalSpent = _accountLockInfo[sender].totalSpent.add(amount);
            }
        }
        _transfer(sender, recipient, amount);
        if (_msgSender() != sender && !isApprovedForAll(sender, _msgSender())) _approve(sender, _msgSender(), allowances - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Time >> decreased allowance below zero"));
        return true;
    }

    function mint(address account, uint256 amount) public override onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function setApprovalForAll(address operator, bool approved) external override whenNotPaused {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[_msgSender()][operator] = approved;
    }
   
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _authorised[owner][operator];
    }

    function isValidLockType(string memory lockType) public override view returns(bool) {
        return _lockTypeCreated[lockType];
    }

    function addLockType(string memory lockType, uint256 lockAmount) external override returns(bool) {
        require(_msgSender() == _creator || isApprovedForAll(_creator, _msgSender()), "Time >> addLockType: sender does not have permission");
        require(bytes(lockType).length > 0, "Time >> addLockType: lock type is empty");
        require(!isValidLockType(lockType), "Time >> addLockType: already added this lock type");

        _lockTypeTable[lockType] = lockAmount;
        _lockTypes.push(lockType);
        _lockTypeCreated[lockType] = true;

        emit AddLockType(lockType, lockAmount);

        return true;
    }

    function getLockTypes() external override view returns(string[] memory) {
        return _lockTypes;
    }

    function getLockTypeAmount(string memory lockType) public override view returns(uint256) {
        require(isValidLockType(lockType), "Time >> getLockTypeAmount: lock type is invalid");

        return _lockTypeTable[lockType];
    }

    function isLockActivate(address account) public override view returns(bool) {
        return _accountLockInfo[account].timestamp > 0;
    }

    // set lockType to account
    function setAccountLockType(address account, string memory userId, string memory lockType) public override returns(bool) {
        require(_msgSender() == _creator || isApprovedForAll(_creator, _msgSender()), "Time >> setAccountLockType: sender does not have permission");
        require(isValidLockType(lockType), "Time >> setAccountLockType: lock type is invalid");
        require(!isLockActivate(account), "Time >> setAccountLockType: already set lock type ");

        LockInfo memory lockInfo;
        lockInfo.userId = userId;
        lockInfo.lockType = lockType;
        lockInfo.timestamp = uint64(block.timestamp % 2**64);

        _accountLockInfo[account] = lockInfo;

        emit SetAccountLockType(account, userId, lockType);
        return true;
    }

    function updateAccountLockType(address account, string memory lockType) external override returns(bool) {
        require(_msgSender() == _creator || isApprovedForAll(_creator, _msgSender()), "Time >> updateAccountLockType: sender does not have permission");
        require(isValidLockType(lockType), "Time >> updateAccountLockType: lock type is invalid");
        require(isLockActivate(account), "Time >> updateAccountLockType: not set lock type yet");

        _accountLockInfo[account].lockType = lockType;

        emit UpdateAccountLockType(account, lockType);
        return true;
    }

    function updateUserIdLockType(address account, string memory userId) external override returns(bool) {
        require(_msgSender() == _creator || isApprovedForAll(_creator, _msgSender()), "Time >> updateUserIdLockType: sender does not have permission");
        require(bytes(userId).length > 0, "Time >> updateUserIdLockType: user id is empty");
        require(isLockActivate(account), "Time >> updateUserIdLockType: not set lock type yet");

        _accountLockInfo[account].userId = userId;
        return true;
    }

    function getAccountLockType(address account) public override view returns(LockInfo memory) {
        return _accountLockInfo[account];
    }

    function getQuotaAmountLeft(address account) external override view returns(bool, uint256, uint64) {
        if (!isLockActivate(account)) return (false, 0, 0);

        LockInfo memory lockInfo = getAccountLockType(account);
        (bool unlimited, uint256 quotaLeft, uint64 milestonePassed) = computeQuotaAmountLeft(lockInfo);
        return (unlimited, quotaLeft, milestonePassed);
    }

    function computeQuotaAmountLeft(LockInfo memory lockInfo) internal view returns(bool, uint256, uint64) {
        uint256 lockAmount = getLockTypeAmount(lockInfo.lockType);
        if (lockAmount == 2**256 - 1) return (true, 0, 0); // unlimited

        uint64 timeElapsed = uint64(block.timestamp % 2**64) - lockInfo.timestamp;
        uint64 milestonePassed = timeElapsed / _lockTypeInterval;
        uint256 quotaLeft = 0;
        if (lockInfo.milestonePassed < milestonePassed) {
            quotaLeft = lockAmount;
        } else if (lockAmount > lockInfo.totalSpent) {
            quotaLeft = lockAmount - lockInfo.totalSpent;
        }
        return (false, quotaLeft, milestonePassed);
    }

    function setLockTypeInterval(uint64 inteval) external returns(bool) {
        require(_msgSender() == _creator, "Time >> setLockTypeInterval: sender does not have permission");
        require(inteval > 0, "Time >> setLockTypeInterval: interval must be greater than zero");

        _lockTypeInterval = inteval;
        return true;
    }

    function getLockTypeInterval() external view returns(uint64) {
        return _lockTypeInterval;
    }

}