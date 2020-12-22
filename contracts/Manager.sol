// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IManager.sol";
import "./interfaces/ILands.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IQuadKey.sol";
import "./libraries/SafeMath.sol";


contract Manager is IManager {
    using SafeMath for uint256;
    string private _name = "PAIRS";

    struct Reward {
        string landId;
        uint256 reward;
    }

    address _creator;
    address _rewardSupplier;
    address _time;
    address _quadkey;
    address _lands;
    mapping(address => mapping(address => bool)) internal _authorised;
    bytes4 private constant ERC20_TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    uint64 _intevalKind;
    
    mapping(address => uint256) _reserve; // reserve allow user buying or upgrading land
    uint256 _landPrice;
    uint256 _upgradableBasePrice;
    uint8 _decimals;

    event ClaimRewardOfLand(address indexed owner, string quadkey, string landId, uint256 reward);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, string quadkey, string landId, uint256 amount);

    constructor(address creator, address time, address lands, address quadkey, uint256 landPrice, uint256 upgradableBasePrice, uint64 intervalKind) {
        _creator = creator;
        _rewardSupplier = _creator;
        _time = time;
        _quadkey = quadkey;
        _lands = lands;
        _decimals = IERC20(_time).decimals();
        _landPrice = landPrice * (10**_decimals);
        _upgradableBasePrice = upgradableBasePrice * (10**_decimals);
        _intevalKind = intervalKind;
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "setCreator: not creator");
        require(address(0) == creator, "setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    function setSupplier(address supplier) public {
        require(msg.sender == _creator, "setSupplier: not creator");
        require(address(0) == supplier, "setSupplier: supplier can not be zero address");

        _rewardSupplier = supplier;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) external override view returns (bool) {
        return _authorised[owner][operator];
    }

    function uintToString(uint256 value) internal pure returns(string memory) {
        if (value == 0) return "0";

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

    function concatString(string memory a, string memory b, string memory c) internal pure returns(string memory) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory cc = bytes(c);
        bytes memory s = new bytes(aa.length + bb.length + cc.length);
        uint i = 0;
        for (uint j = 0; j < aa.length; j++) s[i++] = aa[j];
        for (uint j = 0; j < bb.length; j++) s[i++] = bb[j];
        for (uint j = 0; j < cc.length; j++) s[i++] = cc[j];

        return string(s);
    }

    function deposit(uint256 amount) external override {
        address sender = msg.sender;
        safeTransferFrom(_time, sender, address(this), amount);
        _reserve[sender] = _reserve[sender].add(amount);
    }

    function withdraw(uint256 amount) external override {
        address sender = msg.sender;
        _reserve[sender] = _reserve[sender].sub(amount, "Manager >> withdraw: the reserve is not enough");
        safeTransferFrom(_time, address(this), sender, amount);
    }

    function getReserve(address owner) external override view returns(uint256) {
        return _reserve[owner];
    }

    function getLandPrice(uint256 amount) external override view returns(uint256) {
        return _landPrice.mul(amount);
    }

    function buyLand(string memory quadkey, uint256 amount) external override {
        require(IQuadKey(_quadkey).isOwnerOf(msg.sender, quadkey), "Manager >> buyLand: not owner");
        uint256 price = _landPrice.mul(amount);
        _reserve[msg.sender] = _reserve[msg.sender].sub(price, "Manager >> buyLand: the reserve is not enough");

        safeTransferFrom(_time, address(this), _rewardSupplier, price);
        IQuadKey(_quadkey).issueToken(msg.sender, quadkey, amount);

    }

    function getUpgradableLandPrice(string memory fromLandId, string memory toLandId, uint256 amount) external override view returns(uint256) {
        uint64 fromInterval = ILands(_lands).getTokenInterval(fromLandId);
        uint64 toInterval = ILands(_lands).getTokenInterval(toLandId);
        if (toInterval < fromInterval) return _upgradableBasePrice.mul(amount).mul(fromInterval / toInterval);
        return 0;
    }

    function upgradeLand(string memory quadkey, string memory fromLandId, string memory toLandId, uint256 amount) external override {
        require(IQuadKey(_quadkey).isOwnerOf(msg.sender, quadkey), "Manager >> upgradeLand: not own this quadkey yet");
        
        uint64 fromInterval = ILands(_lands).getTokenInterval(fromLandId);
        uint64 toInterval = ILands(_lands).getTokenInterval(toLandId);
        require(toInterval < fromInterval, "Manager >> upgradeLand: not allow downgrading land");

        uint256 price = _upgradableBasePrice.mul(amount).mul(fromInterval / toInterval);
        _reserve[msg.sender] = _reserve[msg.sender].sub(price, "Manager >> upgradeLand: the reserve is not enough");

        safeTransferFrom(_time, address(this), _rewardSupplier, price);
        ILands(_lands).upgradeLand(msg.sender, quadkey, fromLandId, toLandId, amount);
    }

    function issueLand(address to, string memory quadkey, uint256 amount) public override {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Manager >> issueLand: not have permission");

        IQuadKey(_quadkey).issueToken(to, quadkey, amount);
    }

    function issueLand(address to, string memory quadkey, string memory landId, uint256 amount) public override {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Manager >> issueLand: not have permission");

        IQuadKey(_quadkey).issueToken(to, quadkey, landId, amount);
    }

    function transferLandFrom(address from, address to, string memory quadkey, string memory landId, uint256 amount) public override {
        require(msg.sender == from || _authorised[from][msg.sender], "Manager >> transferLandFrom: not have permission");

        IQuadKey(_quadkey).transferFrom(from, to, quadkey, landId, amount);
    }

    function computeTimeRewards(Tokens memory land, uint64 timestamp) private view returns(uint256 reward, uint64 timeElapsed, uint64 timeLeft) {
        if (land.balance > 0) {
            timeElapsed = timestamp - land.timestamp;
            uint64 interval = ILands(_lands).getTokenInterval(land.id);
            uint64 intervalInSecond = interval * _intevalKind;
            if (timeElapsed >= intervalInSecond) {
                reward = land.balance.mul(timeElapsed / intervalInSecond).mul(interval).mul(10**_decimals);
                timeElapsed = (timeElapsed % intervalInSecond);
            }
            timeLeft = intervalInSecond - timeElapsed;
        }
    }
    
    function getLandIntervalList() external override view returns(string memory Intervals) {
        string[] memory landIDs = ILands(_lands).getTokenIDs();
        Intervals = "";
        for (uint i = 0; i < landIDs.length; i++) {
            uint64 interval = ILands(_lands).getTokenInterval(landIDs[i]);
            if (i == 0) {
                Intervals = concatString(landIDs[i], ":", uintToString(interval));
            } else {
                Intervals = concatString(Intervals, ":", landIDs[i]);
                Intervals = concatString(Intervals, ":", uintToString(interval));
            }
        }
    }

    function getLandList(address owner) external override view returns(string memory rewards) {
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        QuadKeyInfo[] memory quadkeyList = IQuadKey(_quadkey).getTokensOfOwner(owner);
        bool first = true;
        rewards = "";
        for (uint i = 0; i < quadkeyList.length; i++) {
            if (quadkeyList[i].balance > 0) {
                if (first) {
                    rewards = concatString(quadkeyList[i].id,  ":", uintToString(quadkeyList[i].balance));
                    first = false;
                }
                else {
                    rewards = concatString(rewards, ";", quadkeyList[i].id);
                    rewards = concatString(rewards, ":", uintToString(quadkeyList[i].balance));
                }
                string[] memory landIDs = ILands(_lands).getTokenIDs();
                for (uint j = 0; j < landIDs.length; j++) {
                    if(ILands(_lands).isOwnerOf(owner, quadkeyList[i].id, landIDs[j])) {
                        uint256 index = ILands(_lands).tokenIndexOfOwnerById(owner, quadkeyList[i].id, landIDs[j]);
                        Tokens memory land = ILands(_lands).tokenOfOwnerByIndex(owner, quadkeyList[i].id, index);
                        (uint256 reward,,uint64 timeLeft) = computeTimeRewards(land, blockTimestamp);
                        rewards = concatString(rewards, ":", land.id);
                        rewards = concatString(rewards, ":", uintToString(land.balance));
                        rewards = concatString(rewards, ":", uintToString(reward));
                        rewards = concatString(rewards, ":", uintToString(timeLeft));
                    } else {
                        rewards = concatString(rewards, ":", landIDs[j]);
                        rewards = concatString(rewards, ":", "0");
                        rewards = concatString(rewards, ":", "0");
                        rewards = concatString(rewards, ":", "0");
                    }
                }
            }
        }
    }

    function claimRewardOfLand(address owner, string memory quadkey, string memory landId) public override {
        bool isOwner = ILands(_lands).isOwnerOf(owner, quadkey, landId);
        require(isOwner, "Manager >> claimRewardOfLand: not own this land.");
        
        uint256 index = ILands(_lands).tokenIndexOfOwnerById(owner, quadkey, landId);
        Tokens memory land = ILands(_lands).tokenOfOwnerByIndex(owner, quadkey, index);
        require(land.balance > 0, "Manager >> claimRewardOfLand: balance is zero.");

        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        (uint reward, uint64 timeElapsed,) = computeTimeRewards(land, blockTimestamp);
        if (reward > 0) {
            reward = reward;
            safeTransfer(_time, owner, reward);
            uint64 tokenTimestamp = blockTimestamp - timeElapsed;
            ILands(_lands).updateTokenTimestamp(owner, quadkey, landId, tokenTimestamp);

            emit ClaimRewardOfLand(owner, quadkey, landId, reward);
        }
    }

    function claimRewardOfQuadKey(address owner, string memory quadkey) public override {
        bool isOwner = IQuadKey(_quadkey).isOwnerOf(owner, quadkey);
        require(isOwner, "Manager >> claimRewardOfQuadKey: not own this quadkey");

        Tokens[] memory lands = ILands(_lands).getTokensOfOwner(owner, quadkey);
        for (uint i = 0; i < lands.length; i++) {
            if (lands[i].balance > 0) {
                claimRewardOfLand(owner, quadkey, lands[i].id);
            }
        }
    }

    function claimAllRewards(address owner) public override {
        QuadKeyInfo[] memory quadkeyList = IQuadKey(_quadkey).getTokensOfOwner(owner);
        for (uint i = 0; i < quadkeyList.length; i++) {
            if (quadkeyList[i].balance > 0) {
                claimRewardOfQuadKey(owner, quadkeyList[i].id);
            }
        }
    }

    function getIntervalKind() external view returns(uint64) {
        return _intevalKind;
    }

    function setIntervalKind(uint64 interval) public {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Manager >> setIntervalKind: not permission");
        require(interval > 0, "Manager >> setIntervalKind: interval is negative");

        _intevalKind = interval;
    }

    function safeTransfer(address token, address to, uint256 amount) private {
        safeTransferFrom(token, _rewardSupplier, to, amount);
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20_TRANSFER_FROM_SELECTOR, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed.");
    }
}