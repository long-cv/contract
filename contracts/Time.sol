/**
 *Submitted for verification at Etherscan.io on 2019-11-28
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ITime.sol";
import "./libraries/SafeMath.sol";

contract Time is ITime {
    using SafeMath for uint256;
    
    Creators _creators;
    
    address _supplier;

    string private _name;
    
    string private _symbol;
    
    uint8 private _decimals;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => mapping(address => bool)) private _authorised;

    uint256 private _totalSupply;

    mapping(address => LockInfo) private _accountLockInfo;

    mapping(uint8 => uint120) private _lockTypeTable;

    uint8[] private _lockTypes;

    uint64 private _lockTypeInterval; 

    mapping(uint8 => bool) private _lockTypeCreated;

    NewCreatorApproval _newCreatorApproval;

    NewSupplyApproval _newSupplyApproval;

    NewSupplierApproval _newSupplierApproval;

    constructor(address supplier, address creator1, address creator2, address creator3, uint supply, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint8 ulimitedLockType, uint64 lockTypeInterval) {
        _supplier = supplier;
        _creators.creator1 = creator1;
        _creators.creator2 = creator2;
        _creators.creator3 = creator3;
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        uint256 tokenSupply = supply * (10 ** uint256(_decimals));
        _mint(supplier, tokenSupply);
        _lockTypeTable[ulimitedLockType] = 2**120 - 1; // MAX_UINT120
        _lockTypes.push(ulimitedLockType);
        _lockTypeCreated[ulimitedLockType] = true;
        _lockTypeInterval = lockTypeInterval;
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

    function transfer(address recipient, uint120 amount) public override returns(bool) {
        require(isLockActivate(msg.sender), "Time >> transfer: lock type was not set");

        (bool unlimited, uint120 quotaLeft,, uint64 milestonePassed) = computeQuotaAmountLeft(_accountLockInfo[msg.sender]);
        if (!unlimited) {
            require(quotaLeft >= amount, "Time >> transfer: quota left is not enough");

            if (_accountLockInfo[msg.sender].milestonePassed < milestonePassed) {
                _accountLockInfo[msg.sender].milestonePassed = milestonePassed;
                _accountLockInfo[msg.sender].totalSpent = amount;
            } else {
                _accountLockInfo[msg.sender].totalSpent += amount;
            }
        }
        _transfer(msg.sender, recipient, uint256(amount));
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint120 amount) public override returns(bool) {
        require(isLockActivate(sender), "Time >> transferFrom: lock type was not set");

        (bool unlimited, uint120 quotaLeft,, uint64 milestonePassed) = computeQuotaAmountLeft(_accountLockInfo[sender]);
        if (!unlimited) {
            require(quotaLeft >= amount, "Time >> transferFrom: quota left is not enough");

            if (_accountLockInfo[sender].milestonePassed < milestonePassed) {
                _accountLockInfo[sender].milestonePassed = milestonePassed;
                _accountLockInfo[sender].totalSpent = amount;
            } else {
                _accountLockInfo[sender].totalSpent += amount;
            }
        }
        _transfer(sender, recipient, uint256(amount));
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Time >> transferFrom: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Time >> decreaseAllowance: decreased allowance below zero"));
        return true;
    }

    function transferFromOperator(address recipient, uint256 amount) public override returns(bool) {
        require(isOperator(msg.sender), "Time >> transferFromOperator: sender does not have permission");

        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFromSupplier(address recipient, uint256 amount) public override returns(bool) {
        require(isOperator(msg.sender), "Time >> transferFromSupplier: sender does not have permission");

        _transfer(_supplier, recipient, amount);
        return true;
    }

    function transferToSupplier(uint256 amount) public override returns(bool) {
        _transfer(msg.sender, _supplier, amount);
        return true;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
    }
   
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _authorised[owner][operator];
    }

    function isValidLockType(uint8 lockType) public override view returns(bool) {
        return _lockTypeCreated[lockType];
    }

    function addLockType(uint8 lockType, uint120 lockAmount) external override returns(bool) {
        require(isOperator(msg.sender), "Time >> addLockType: sender does not have permission");
        require(!isValidLockType(lockType), "Time >> addLockType: already added this lock type");

        _lockTypeTable[lockType] = lockAmount;
        _lockTypes.push(lockType);
        _lockTypeCreated[lockType] = true;

        emit AddLockType(lockType, lockAmount);

        return true;
    }

    function updateLockType(uint8 lockType, uint120 lockAmount) external override returns(bool) {
        require(isOperator(msg.sender), "Time >> updateLockType: sender does not have permission");
        require(isValidLockType(lockType), "Time >> updateLockType: the lock type is invalid");

        _lockTypeTable[lockType] = lockAmount;

        emit UpdateLockType(lockType, lockAmount);

        return true;
    }

    function getLockTypes() external override view returns(uint8[] memory) {
        return _lockTypes;
    }

    function getLockTypeAmount(uint8 lockType) public override view returns(uint120) {
        require(isValidLockType(lockType), "Time >> getLockTypeAmount: lock type is invalid");

        return _lockTypeTable[lockType];
    }

    function isLockActivate(address account) public override view returns(bool) {
        return _accountLockInfo[account].timestamp > 0;
    }

    // set lockType to account
    function setAccountLockType(address account, uint8 lockType) public override returns(bool) {
        require(isOperator(msg.sender), "Time >> setAccountLockType: sender does not have permission");
        require(isValidLockType(lockType), "Time >> setAccountLockType: lock type is invalid");
        require(!isLockActivate(account), "Time >> setAccountLockType: already set lock type ");

        LockInfo memory lockInfo;
        lockInfo.lockType = lockType;
        lockInfo.timestamp = uint64(block.timestamp % 2**64);

        _accountLockInfo[account] = lockInfo;

        emit SetAccountLockType(account, lockType);
        return true;
    }

    function updateAccountLockType(address account, uint8 lockType) external override returns(bool) {
        require(isOperator(msg.sender), "Time >> updateAccountLockType: sender does not have permission");
        require(isValidLockType(lockType), "Time >> updateAccountLockType: lock type is invalid");
        require(isLockActivate(account), "Time >> updateAccountLockType: not set lock type yet");

        _accountLockInfo[account].lockType = lockType;

        emit UpdateAccountLockType(account, lockType);
        return true;
    }

    function getAccountLockType(address account) public override view returns(LockInfo memory) {
        return _accountLockInfo[account];
    }

    function getQuotaAmountLeft(address account) external override view returns(bool, uint120, uint120, uint64) {
        if (!isLockActivate(account)) return (false, 0, 0, 0);

        LockInfo memory lockInfo = getAccountLockType(account);
        (bool unlimited, uint120 quotaLeft, uint120 lockAmount, uint64 milestonePassed) = computeQuotaAmountLeft(lockInfo);
        return (unlimited, quotaLeft, lockAmount, milestonePassed);
    }

    function computeQuotaAmountLeft(LockInfo memory lockInfo) internal view returns(bool, uint120, uint120, uint64) {
        uint120 lockAmount = getLockTypeAmount(lockInfo.lockType);
        if (lockAmount == 2**120 - 1) return (true, 0, 0, 0); // unlimited

        uint64 timeElapsed = uint64(block.timestamp % 2**64) - lockInfo.timestamp;
        uint64 milestonePassed = timeElapsed / _lockTypeInterval;
        uint120 quotaLeft = 0;
        if (lockInfo.milestonePassed < milestonePassed) {
            quotaLeft = lockAmount;
        } else if (lockAmount > lockInfo.totalSpent) {
            quotaLeft = lockAmount - lockInfo.totalSpent;
        }
        return (false, quotaLeft, lockAmount, milestonePassed);
    }

    function setLockTypeInterval(uint64 inteval) external returns(bool) {
        require(isOperator(msg.sender), "Time >> setLockTypeInterval: sender does not have permission");
        require(inteval > 0, "Time >> setLockTypeInterval: interval must be greater than zero");

        _lockTypeInterval = inteval;
        return true;
    }

    function getLockTypeInterval() external view returns(uint64) {
        return _lockTypeInterval;
    }

    function getCreatorIndex(address creator) internal view returns(uint8) {
        Creators memory creators = _creators;
        if (creator == creators.creator1) return 1;
        if (creator == creators.creator2) return 2;
        if (creator == creators.creator3) return 3;

        return 0; // not a creator;
    }

    function setNewCreator(address oldCreator, address newCreator) external returns(bool) {
        uint8 creatorIndex = getCreatorIndex(msg.sender);
        require(creatorIndex > 0, "Time >> setNewCreator: sender does not have permission");
        uint8 oldCreatorIndex = getCreatorIndex(oldCreator);
        require(oldCreatorIndex > 0, "Time >> setNewCreator: address applied on is not a creator");
        require(address(0) != newCreator, "Time >> setNewCreator: new creator can not be zero address");
        require(_creators.creator1 != newCreator, "Time >> setNewCreator: new creator can not be creator 1");
        require(_creators.creator2 != newCreator, "Time >> setNewCreator: new creator can not be creator 2");
        require(_creators.creator3 != newCreator, "Time >> setNewCreator: new creator can not be creator 3");
        require(_supplier != newCreator, "Time >> setNewCreator: new creator can not be supplier");

        _newCreatorApproval.oldCreator = oldCreator;
        _newCreatorApproval.newCreator = newCreator;
        _newCreatorApproval.approved = uint8(1 << creatorIndex);

        return true;
    }

    function approveNewCreator(bool approved) external returns(bool) {
        uint8 creatorIndex = getCreatorIndex(msg.sender);
        require(creatorIndex > 0, "Time >> approveNewCreator: sender does not have permission");
        require(_newCreatorApproval.approved > 0, "Time >> approveNewCreator: need to set new creator first");

        if (!approved) {
            _newCreatorApproval.approved &= uint8(~(1 << creatorIndex)); // change to unacceptable status
            return true;
        }

        NewCreatorApproval memory creatorApproval = _newCreatorApproval;
        creatorApproval.approved |= uint8(1 << creatorIndex);
        uint8 tatalApproval = ((creatorApproval.approved >> 3) & 0x01) + 
                            ((creatorApproval.approved >> 2) & 0x01) + 
                            ((creatorApproval.approved >> 1) & 0x01);
        // 2 creators accepted
        if (tatalApproval >= 2) {
            Creators memory creators = _creators;
            if (creatorApproval.oldCreator == creators.creator1) {
                _creators.creator1 = creatorApproval.newCreator;
                _newCreatorApproval.approved = 0;
                ChangeCreator(creators.creator1, _creators.creator1);
               return true;
            }
            if (creatorApproval.oldCreator == creators.creator2) {
                _creators.creator2 = creatorApproval.newCreator;
                _newCreatorApproval.approved = 0;
                ChangeCreator(creators.creator2, _creators.creator2);
               return true;
            }
            if (creatorApproval.oldCreator == creators.creator3) {
                _creators.creator3 = creatorApproval.newCreator;
                _newCreatorApproval.approved = 0;
                ChangeCreator(creators.creator3, _creators.creator3);
               return true;
            }
        }
        _newCreatorApproval.approved = creatorApproval.approved ;
        return true;
    }

    function getCreators() external view returns(Creators memory) {
        return _creators;
    }

    function getSupplier() external view returns(address) {
        return _supplier;
    }

    function isOperator(address operator) public view returns(bool) {
        Creators memory creators = _creators;
        return (isApprovedForAll(creators.creator1, operator) && 
                isApprovedForAll(creators.creator2, operator) && 
                isApprovedForAll(creators.creator3, operator));
    }

    function setNewSupplyAmount(uint248 amount) external returns(bool) {
        uint8 creatorIndex = getCreatorIndex(msg.sender);
        require(creatorIndex > 0, "Time >> setNewSupplyAmount: sender does not have permission");

        _newSupplyApproval.amount = amount;
        _newSupplyApproval.approved = uint8(1 << creatorIndex);
        return true;
    }

    function approveNewSupplyAmount(bool approved) external returns(bool) {
        uint8 creatorIndex = getCreatorIndex(msg.sender);
        require(creatorIndex > 0, "Time >> approveNewSupplyAmount: sender does not have permission");
        require(_newSupplyApproval.approved > 0, "Time >> approveNewSupplyAmount: need to set new supply amount first");
        // not accept, reset everthing.
        if (!approved) {
            _newSupplyApproval.amount = 0;
            _newSupplyApproval.approved = 0;
            return true;
        }

        NewSupplyApproval memory supplyApproval = _newSupplyApproval;
        supplyApproval.approved |= uint8(1 << creatorIndex);
        // 0x0E = 00001110: 3 creators accepted
        if (supplyApproval.approved == 0x0E) {
            _mint(_supplier, supplyApproval.amount);
            _newSupplyApproval.amount = 0;
            _newSupplyApproval.approved = 0;
            return true;
        }
        _newSupplyApproval.approved = supplyApproval.approved;
        return true;
    }

    function setNewSupplier(address newSupplier) external returns(bool) {
        uint8 creatorIndex = getCreatorIndex(msg.sender);
        require(creatorIndex > 0, "Time >> setNewSupplier: sender does not have permission");
        require(address(0) != newSupplier, "Time >> setNewSupplier: new supplier can not be zero address");
        require(_creators.creator1 != newSupplier, "Time >> setNewSupplier: new supplier can not be the creator 1");
        require(_creators.creator2 != newSupplier, "Time >> setNewSupplier: new supplier can not be the creator 2");
        require(_creators.creator3 != newSupplier, "Time >> setNewSupplier: new supplier can not be the creator 3");
        require(_supplier != newSupplier, "Time >> setNewSupplier: new supplier can not be the current supplier");

        _newSupplierApproval.newSupplier = newSupplier;
        _newSupplierApproval.approved = uint8(1 << creatorIndex);
        return true;
    }

    function approveNewSupplier(bool approved) external returns(bool) {
        uint8 creatorIndex = getCreatorIndex(msg.sender);
        require(creatorIndex > 0, "Time >> approveNewSupplier: sender does not have permission");
        require(_newSupplierApproval.approved > 0, "Time >> approveNewSupplier: need to set new supplier first");

        // not accept, reset everthing.
        if (!approved) {
            _newSupplierApproval.approved = 0;
            return true;
        }

        NewSupplierApproval memory supplierApproval = _newSupplierApproval;
        supplierApproval.approved |= uint8(1 << creatorIndex);
        // 0x0E = 00001110: 3 creators accepted
        if (supplierApproval.approved == 0x0E) {
            address supplier = _supplier;
            _balances[supplierApproval.newSupplier] = _balances[supplierApproval.newSupplier].add(_balances[supplier]);
            _balances[supplier] = 0;
            _supplier = supplierApproval.newSupplier;
            _newSupplierApproval.approved = 0;
            ChangeSupplier(supplier, _supplier);

            return true;
        }
        _newSupplierApproval.approved = supplierApproval.approved;
        return true;
    }

    function getNewCreatorStatus() external view returns(NewCreatorApproval memory) {
        return _newCreatorApproval;
    }

    function getNewSupplyStatus() external view returns(NewSupplyApproval memory) {
        return _newSupplyApproval;
    }

    function getNewSupplerStatus() external view returns(NewSupplierApproval memory) {
        return _newSupplierApproval;
    }
}