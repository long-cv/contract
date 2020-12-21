//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

struct Tokens {
    string id;
    uint256 balance;
    uint64 timestamp;
}

struct QuadKeyInfo {
    string id;
    uint256 balance;
}

struct Supplies {
    uint256 totalIdSupplies;
    uint256 totalTokenSupples;
}