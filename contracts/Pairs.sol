// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/ILands.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract Pairs {
    using SafeMath for uint256;
    string private _name = "PAIRS";

    struct Reward {
        string landId;
        uint256 reward;
    }

    address _creator;
    address _supplier;
    address _time;
    address _lands;
    uint64 _timeRewardInterval;
    bytes4 private constant ERC20_TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant ERC20_TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant ERC20_DECIMALS_SELECTOR = bytes4(keccak256(bytes('decimals()')));

    event ClaimTimeRewards(address indexed owner, string tokeId, uint256 times);
    event ClaimAllTimeRewards(address indexed owner, uint256 times);

    constructor(address creator, address time, address lands) {
        _creator = creator;
        _supplier = _creator;
        _time = time;
        _lands = lands;
        _timeRewardInterval = 1 days;
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "setCreator: not creator");
        require(address(0) == creator, "setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    function setSupplier(address supplier) public {
        require(msg.sender == _creator, "setSupplier: not creator");
        require(address(0) == supplier, "setSupplier: supplier can not be zero address");

        _supplier = supplier;
    }

    function uintToString(uint256 value) internal pure returns(string memory){
        uint maxLength = 100;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
        while (value != 0) {
            uint remainder = (value % 10);
            value /= 10;
            reversed[i++] = byte(uint8(48 + remainder)); // "0" = 48
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }

        return string(s);
    }

    function concatString(string memory a, string memory b, string memory c, string memory d, 
                            string memory e, string memory f, string memory g) internal pure returns(string memory) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory cc = bytes(c);
        bytes memory dd = bytes(d);
        bytes memory ee = bytes(e);
        bytes memory ff = bytes(f);
        bytes memory gg = bytes(g);
        bytes memory s = new bytes(aa.length + bb.length + cc.length + dd.length + ee.length + ff.length + gg.length);
        uint i = 0;
        for (uint j = 0; j < aa.length; j++) s[i++] = aa[j];
        for (uint j = 0; j < bb.length; j++) s[i++] = bb[j];
        for (uint j = 0; j < cc.length; j++) s[i++] = cc[j];
        for (uint j = 0; j < dd.length; j++) s[i++] = dd[j];
        for (uint j = 0; j < ee.length; j++) s[i++] = ee[j];
        for (uint j = 0; j < ff.length; j++) s[i++] = ff[j];
        for (uint j = 0; j < gg.length; j++) s[i++] = gg[j];

        return string(s);
    }

    function computeTimeRewards(Tokens memory land, uint64 timestamp) private view returns(uint256 reward, uint64 timeLeft) {
        uint64 timeElapsed = timestamp - land.timestamp;
        if (timeElapsed >= _timeRewardInterval) {
            reward = land.balance.mul(timeElapsed / _timeRewardInterval);
            timeLeft = (timeElapsed % _timeRewardInterval);
        }
    }

    function getTokenInfoList(address owner) public view returns(string memory rewards) {
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        Tokens[] memory lands = ILands(_lands).getTokensOfOwner(owner);
        for (uint i = 0; i < lands.length; i++) {
            if (lands[i].balance > 0) {
                (uint256 reward, ) = computeTimeRewards(lands[i], blockTimestamp);
                rewards = concatString(rewards, lands[i].id,  ":", uintToString(lands[i].balance), ":", uintToString(reward), ";");
            }
        }
    }

    function claimTimeRewards(address owner, string memory tokenId) public {
        bool isOwner = ILands(_lands).isOwnerOf(owner, tokenId);
        require(isOwner, "Pairs, claimTimeRewards: not owner.");
        uint256 index = ILands(_lands).tokenIndexOfOwnerById(owner, tokenId);
        Tokens memory land = ILands(_lands).tokenOfOwnerByIndex(owner, index);
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        (uint reward, uint64 timeLeft) = computeTimeRewards(land, blockTimestamp);
        require(reward > 0, "claimTimeRewards: no time to claim.");
        uint8 decimals = IERC20(_time).decimals();
        reward = reward * (10**decimals);
        safeTransfer(_time, owner, reward);
        uint64 tokenTimestamp = blockTimestamp - timeLeft;
        ILands(_lands).updateTokenTimestamp(owner, tokenId, tokenTimestamp);

        emit ClaimTimeRewards(owner, tokenId, reward);
    }

    function claimAllTimeRewards(address owner) public {
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        Tokens[] memory lands = ILands(_lands).getTokensOfOwner(owner);
        uint256 rewards = 0;
        for (uint i = 0; i < lands.length; i++) {
            if (lands[i].balance > 0) {
                (uint256 reward, uint64 timeLeft) = computeTimeRewards(lands[i], blockTimestamp);
                if (reward > 0) {
                    rewards = rewards.add(reward);
                    uint64 tokenTimestamp = blockTimestamp - timeLeft;
                    ILands(_lands).updateTokenTimestamp(owner, lands[i].id, tokenTimestamp);
                }
            }
        }
        require(rewards > 0, "claimAllTimeRewards: no time to claim.");
        (, bytes memory data) = _time.call(abi.encodeWithSelector(ERC20_DECIMALS_SELECTOR));
        uint8 decimal = abi.decode(data, (uint8));
        rewards = rewards * (10**decimal);
        safeTransfer(_time, owner, rewards);
        emit ClaimAllTimeRewards(owner, rewards);
    }

    function safeTransfer(address token, address to, uint256 amount) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20_TRANSFER_FROM_SELECTOR, _supplier, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed.");
    }

    function getTimeRewardInterval() public view returns(uint64) {
        return _timeRewardInterval;
    }

    function setTimeRewardInterval(uint64 interval) public {
        require(msg.sender == _creator, "setTimeRewardInterval: not creator");
        require(interval > 0, "setTimeRewardInterval: interval is negative");

        _timeRewardInterval = interval;
    }
}