// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;

import "./interfaces/ILands.sol";
import "./interfaces/IERC20.sol";
import "./ERC20Detailed.sol";
import "./libraries/SafeMath.sol";

contract Pairs is ERC20Detailed {
    using SafeMath for uint;

    address _creator;
    address _time;
    address _lands;
    uint64 _timeRewardInterval;
    mapping(uint8 => uint256) _weightPrice;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event ClaimTimeRewards(address indexed recipient, string tokeId, uint times);

    constructor(address time, address lands, string memory name, string memory symbol, uint8 decimals) ERC20Detailed(name, symbol, decimals) {
        _creator = msg.sender;
        _time = time;
        _lands = lands;
        _timeRewardInterval = 1 days;
        _weightPrice[0] = 1 * (10**decimals);
        _weightPrice[1] = 2 * (10**decimals);
        _weightPrice[2] = 3 * (10**decimals);
        _weightPrice[3] = 4 * (10**decimals);
        _weightPrice[4] = 5 * (10**decimals);
        _weightPrice[5] = 6 * (10**decimals);
        _weightPrice[6] = 7 * (10**decimals);
        _weightPrice[7] = 8 * (10**decimals);
        _weightPrice[8] = 9 * (10**decimals);
        _weightPrice[9] = 10 * (10**decimals);
    }

    function computeTimeRewards(string memory tokenId, uint64 timestamp) private view returns(uint256 reward, uint64 timeLeft) {
        uint64 tokenTimestamp = ILands(_lands).getTokenTimestamp(tokenId);
        require(tokenTimestamp > 0, "not set timestamp yet");

        uint64 timeElapsed = timestamp - tokenTimestamp;
        if (timeElapsed >= _timeRewardInterval) {
            uint8 weight = ILands(_lands).getTokenWeight(tokenId);
            uint256 weightPrice = _weightPrice[weight];
            reward = weightPrice.mul(timeElapsed / _timeRewardInterval);
            timeLeft = (timeElapsed % _timeRewardInterval);
        }
    }

    function getTimeRewards(string memory tokenId) public view returns(uint256 reward) {
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        (reward, ) = computeTimeRewards(tokenId, blockTimestamp);
    }

    function claimTimeRewards(string memory tokenId, address recipient) public {
        address owner = ILands(_lands).ownerOf(tokenId);
        require(recipient == owner, "Pairs, claimTimeRewards: not owner.");

        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        (uint reward, uint64 timeLeft) = computeTimeRewards(tokenId, blockTimestamp);
        if (reward > 0) {
            safeTransfer(_time, recipient, reward);
            uint64 tokenTimestamp = blockTimestamp - timeLeft;
            ILands(_lands).updateTokenTimestamp(tokenId, tokenTimestamp);

            emit ClaimTimeRewards(recipient, tokenId, reward);
        }
    }

    function safeTransfer(address token, address to, uint256 amount) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Pairs, safeTransfer: failed.");
    }

    function getTimeRewarInterval() public view returns(uint64) {
        return _timeRewardInterval;
    }

    function setTimeRewardInterval(uint64 interval) public {
        require(msg.sender == _creator, "Pairs, setTimeRewardInterval: not creator");
        require(interval > 0, "Pairs, setTimeRewardInterval: interval is negative");

        _timeRewardInterval = interval;
    }
}