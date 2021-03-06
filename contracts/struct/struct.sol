//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;

struct LandInfo {
    uint16   id;
    uint176 amount;
    uint64  timestamp;
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