// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IManager.sol";
import "./interfaces/ILands.sol";
import "./interfaces/ITime.sol";
import "./interfaces/IQuadkey.sol";
import "./libraries/SafeMath.sol";

contract Manager is IManager {
    using SafeMath for uint256;
    string private _name = "Manager";

    address _creator;
    address _time;
    address _quadkey;
    address _lands;
    mapping(address => mapping(address => bool)) internal _authorised;
    bytes4 private constant TIME_TRANSFER_FROM_SUPPLIER_SELECTOR = bytes4(keccak256(bytes('transferFromSupplier(address,uint256)')));
    bytes4 private constant TIME_TRANSFER_TO_SUPPLIER_SELECTOR = bytes4(keccak256(bytes('transferToSupplier(address,uint120)')));

    uint64 _intevalKind;
    
    uint256 _landPrice;
    uint256 _upgradableBasePrice;
    uint8 _decimals;

    constructor(address creator, address time, address lands, address quadkey, uint256 landPrice, uint256 upgradableBasePrice, uint64 intervalKind) {
        _creator = creator;
        _time = time;
        _quadkey = quadkey;
        _lands = lands;
        _decimals = ITime(_time).decimals();
        _landPrice = landPrice * (10**_decimals);
        _upgradableBasePrice = upgradableBasePrice * (10**_decimals);
        _intevalKind = intervalKind;
    }

    function setCreator(address creator) external {
        require(msg.sender == _creator, "Manager >> setCreator: not creator");
        require(address(0) != creator, "Manager >> setCreator: creator can not be zero address");
        
        _creator = creator;
    }

    function getCreator() external view returns(address) {
        return _creator;
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

    function getLandPrice(uint256 amount) external override view returns(uint256) {
        return _landPrice.mul(amount);
    }

    function buyLand(string memory quadkey, uint176 amount) external override {
        require(IQuadkey(_quadkey).isOwnerOf(msg.sender, quadkey), "Manager >> buyLand: not owner");
        uint256 price = _landPrice.mul(amount);

        safeTransferToSupplier(_time, msg.sender, price);
       IQuadkey(_quadkey).issueToken(msg.sender, quadkey, amount);
    }

    function getUpgradableLandPrice(uint16 fromLandId, uint16 toLandId, uint256 amount) external override view returns(uint256) {
        uint64 fromInterval = ILands(_lands).getTokenInterval(fromLandId);
        uint64 toInterval = ILands(_lands).getTokenInterval(toLandId);
        if (toInterval < fromInterval) return _upgradableBasePrice.mul(amount).mul(fromInterval / toInterval);
        return 0;
    }

    function upgradeLand(string memory quadkey, uint16 fromLandId, uint16 toLandId, uint176 amount) external override {
        require(IQuadkey(_quadkey).isOwnerOf(msg.sender, quadkey), "Manager >> upgradeLand: not own this quadkey yet");
        
        uint64 fromInterval = ILands(_lands).getTokenInterval(fromLandId);
        uint64 toInterval = ILands(_lands).getTokenInterval(toLandId);
        require(toInterval < fromInterval, "Manager >> upgradeLand: not allow downgrading land");

        uint256 price = _upgradableBasePrice.mul(amount).mul(fromInterval / toInterval);

        safeTransferToSupplier(_time, msg.sender, price);
        ILands(_lands).upgradeLand(msg.sender, quadkey, fromLandId, toLandId, amount);
    }

    function issueLand(address to, string memory quadkey, uint176 amount) public override {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Manager >> issueLand: not have permission");

        IQuadkey(_quadkey).issueToken(to, quadkey, amount);
    }

    function issueLand(address to, string memory quadkey, uint16 landId, uint176 amount) public override {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Manager >> issueLand: not have permission");

        IQuadkey(_quadkey).issueToken(to, quadkey, landId, amount);
    }
 
    function transferLandFrom(address from, address to, string memory quadkey, uint16 landId, uint176 amount) public override {
        require(msg.sender == from || _authorised[from][msg.sender], "Manager >> transferLandFrom: not have permission");

        IQuadkey(_quadkey).transferFrom(from, to, quadkey, landId, amount);
    }

    function computeTimeRewards(LandInfo memory land, uint64 timestamp) private view returns(uint256 reward, uint64 timeElapsed, uint64 timeLeft) {
        if (land.amount > 0) {
            timeElapsed = timestamp - land.timestamp;
            uint64 interval = ILands(_lands).getTokenInterval(land.id);
            uint64 intervalInSecond = interval * _intevalKind;
            if (timeElapsed >= intervalInSecond) {
                reward = uint256(land.amount).mul(timeElapsed / intervalInSecond).mul(interval).mul(10**_decimals);
                timeElapsed = (timeElapsed % intervalInSecond);
            }
            timeLeft = intervalInSecond - timeElapsed;
        }
    }
    
    function getLandIntervalList() external override view returns(string memory intervals) {
        uint16[] memory landIDs = ILands(_lands).getTokenIDs();
        intervals = "";
        for (uint i = 0; i < landIDs.length; i++) {
            uint64 interval = ILands(_lands).getTokenInterval(landIDs[i]);
            if (i == 0) {
                intervals = concatString(uintToString(landIDs[i]), ":", uintToString(interval));
            } else {
                intervals = concatString(intervals, ":", uintToString(landIDs[i]));
                intervals = concatString(intervals, ":", uintToString(interval));
            }
        }
    }

    function getLandList(address owner) external override view returns(string memory list) {
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        string[] memory quadkeyList = IQuadkey(_quadkey).getTokensOfOwner(owner);
        bool first = true;
        list = "";
        for (uint i = 0; i < quadkeyList.length; i++) {
            uint256 amount = IQuadkey(_quadkey).getTokenAmountOfOwner(owner, quadkeyList[i]);
            if (first) {
                list = concatString(quadkeyList[i],  ":", uintToString(amount));
                first = false;
            }
            else {
                list = concatString(list, ";", quadkeyList[i]);
                list = concatString(list, ":", uintToString(amount));
            }
            uint16[] memory landIDs = ILands(_lands).getTokenIDs();
            for (uint j = 0; j < landIDs.length; j++) {
                if (ILands(_lands).isOwnerOf(owner, quadkeyList[i], landIDs[j])) {
                    uint256 index = ILands(_lands).tokenIndexOfOwnerById(owner, quadkeyList[i], landIDs[j]);
                    LandInfo memory land = ILands(_lands).tokenOfOwnerByIndex(owner, quadkeyList[i], index);
                    (uint256 reward,,uint64 timeLeft) = computeTimeRewards(land, blockTimestamp);
                    list = concatString(list, ":", uintToString(land.id));
                    list = concatString(list, ":", uintToString(land.amount));
                    list = concatString(list, ":", uintToString(reward));
                    list = concatString(list, ":", uintToString(timeLeft));
                } else {
                    list = concatString(list, ":", uintToString(landIDs[j]));
                    list = concatString(list, ":", "0");
                    list = concatString(list, ":", "0");
                    list = concatString(list, ":", "0");
                }
            }
        }
    }

    function claimLandReward(address owner, string memory quadkey, uint16 landId) public override {
        bool isOwner = ILands(_lands).isOwnerOf(owner, quadkey, landId);
        require(isOwner, "Manager >> claimRewardOfLand: not own this land.");
        
        uint256 index = ILands(_lands).tokenIndexOfOwnerById(owner, quadkey, landId);
        LandInfo memory land = ILands(_lands).tokenOfOwnerByIndex(owner, quadkey, index);
        require(land.amount > 0, "Manager >> claimRewardOfLand: amount is zero.");

        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        (uint reward, uint64 timeElapsed,) = computeTimeRewards(land, blockTimestamp);
        if (reward > 0) {
            reward = reward;
            safeTransferFromSupplier(_time, owner, reward);
            uint64 tokenTimestamp = blockTimestamp - timeElapsed;
            ILands(_lands).updateTokenTimestamp(owner, quadkey, landId, tokenTimestamp);

            emit ClaimRewardOfLand(owner, quadkey, landId, reward);
        }
    }

    function claimQuadkeyReward(address owner, string memory quadkey) public override {
        bool isOwner = IQuadkey(_quadkey).isOwnerOf(owner, quadkey);
        require(isOwner, "Manager >> claimRewardOfQuadKey: not own this quadkey");

        LandInfo[] memory lands = ILands(_lands).getTokensOfOwner(owner, quadkey);
        for (uint i = 0; i < lands.length; i++) {
            if (lands[i].amount > 0) {
                claimLandReward(owner, quadkey, lands[i].id);
            }
        }
    }

    function claimAllReward(address owner) public override {
        string[] memory quadkeyList = IQuadkey(_quadkey).getTokensOfOwner(owner);
        for (uint i = 0; i < quadkeyList.length; i++) {
            claimQuadkeyReward(owner, quadkeyList[i]);
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

    function safeTransferFromSupplier(address token, address to, uint256 amount) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TIME_TRANSFER_FROM_SUPPLIER_SELECTOR, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Manager >> safeTransferFromSupplier: failed.");
    }

    function safeTransferToSupplier(address token, address from, uint256 amount) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TIME_TRANSFER_TO_SUPPLIER_SELECTOR, from, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Manager >> safeTransferToSupplier: failed.");
    }

    function getDecimals() external view returns(uint16) {
        return _decimals;
    }
}
