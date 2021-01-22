//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;

struct Tokens {
    string  id;
    uint256 balance;
    uint64  timestamp;
}

struct QuadKeyInfo {
    string  id;
    uint256 balance;
}

struct Supplies {
    uint256 totalIdSupplies;
    uint256 totalTokenSupples;
}

struct LockInfo {
    uint8   lockType;
    uint64  timestamp;
    uint64  milestonePassed;
    uint120 totalSpent;
}

struct Creators {
    address creator1;
    address creator2;
    address creator3;
}

struct NewCreatorApproval {
    address oldCreator;
    address newCreator;
    uint8   approved;
}

struct NewSupplyApproval {
    uint248 amount;
    uint8   approved;
}

struct NewSupplierApproval {
    address newSupplier;
    uint8   approved;
}