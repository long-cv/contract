// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/ILands.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IQuadKey.sol";
import "./libraries/SafeMath.sol";

contract Manager {
    using SafeMath for uint256;
    string private _name = "PAIRS";

    struct Reward {
        string landId;
        uint256 reward;
    }

    address _creator;
    address _supplier;
    address _time;
    address _quadkey;
    address _lands;
    mapping(address => mapping(address => bool)) internal _authorised;
    bytes4 private constant ERC20_TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    uint64 _intevalKind;

    event ClaimRewardOfLand(address indexed owner, string quadkey, string landId, uint256 reward);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, string quadkey, string landId, uint256 amount);

    constructor(address creator, address time, address quadkey, address lands) {
        _creator = creator;
        _supplier = _creator;
        _time = time;
        _quadkey = quadkey;
        _lands = lands;
        _intevalKind = 1 days;
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

    function setApprovalForAll(address operator, bool approved) external {
        emit ApprovalForAll(msg.sender, operator, approved);
        
        _authorised[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
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

    function issueLand(address to, string memory quadkey, string memory landId, uint256 amount) public {
        require(msg.sender == _creator || _authorised[_creator][msg.sender], "Manager >> issueLand: not have permission");

        IQuadKey(_quadkey).issueToken(to, quadkey, amount);
        ILands(_lands).issueToken(to, quadkey, landId, amount);

        Transfer(msg.sender, to, quadkey, landId, amount);
    }

    function transferLandFrom(address from, address to, string memory quadkey, string memory landId, uint256 amount) public {
        require(msg.sender == from || _authorised[from][msg.sender], "Manager >> transferLandFrom: not have permission");

        IQuadKey(_quadkey).transferFrom(from, to, quadkey, amount);
        ILands(_lands).transferFrom(from, to, quadkey, landId, amount);

        Transfer(from, to, quadkey, landId, amount);
    }

    function computeTimeRewards(Tokens memory land, uint64 timestamp) private view returns(uint256 reward, uint64 timeLeft) {
        if (land.balance > 0) {
            uint64 timeElapsed = timestamp - land.timestamp;
            uint64 interval = ILands(_lands).getTokenInterval(land.id);
            uint64 intervalInSecond = interval * _intevalKind;
            if (timeElapsed >= intervalInSecond) {
                reward = land.balance.mul(timeElapsed / intervalInSecond).mul(interval);
                timeLeft = (timeElapsed % intervalInSecond);
            }
        }
    }

    function getTokenInfoList(address owner) public view returns(string memory rewards) {
        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        QuadKeyInfo[] memory quadkeyList = IQuadKey(_quadkey).getTokensOfOwner(owner);
        bool first = true;
        for (uint i = 0; i < quadkeyList.length; i++) {
            if (quadkeyList[i].balance > 0) {
                if (first) {
                    rewards = concatString(quadkeyList[i].id,  ":", uintToString(quadkeyList[i].balance), "", "", "", "");
                    first = false;
                }
                else {
                    rewards = concatString(rewards, ";", quadkeyList[i].id,  ":", uintToString(quadkeyList[i].balance), "", "");
                }
                string[] memory landIDs = ILands(_lands).getTokenIDs();
                for (uint j = 0; j < landIDs.length; j++) {
                    if(ILands(_lands).isOwnerOf(owner, quadkeyList[i].id, landIDs[j])) {
                        uint index = ILands(_lands).tokenIndexOfOwnerById(owner, quadkeyList[i].id, landIDs[j]);
                        Tokens memory land = ILands(_lands).tokenOfOwnerByIndex(owner, quadkeyList[i].id, index);
                        (uint256 reward, ) = computeTimeRewards(land, blockTimestamp);
                        rewards = concatString(rewards, ":", land.id,  ":", uintToString(land.balance), ":", uintToString(reward));
                    } else {
                        rewards = concatString(rewards, ":", landIDs[j],  ":", "0", ":", "0");
                    }
                }
            }
        }
    }

    function claimRewardOfLand(address owner, string memory quadkey, string memory landId) public {
        bool isOwner = ILands(_lands).isOwnerOf(owner, quadkey, landId);
        require(isOwner, "Manager >> claimRewardOfLand: not own this land.");
        
        uint256 index = ILands(_lands).tokenIndexOfOwnerById(owner, quadkey, landId);
        Tokens memory land = ILands(_lands).tokenOfOwnerByIndex(owner, quadkey, index);
        require(land.balance > 0, "Manager >> claimRewardOfLand: balance is zero.");

        uint64 blockTimestamp = uint64(block.timestamp % 2**64);
        (uint reward, uint64 timeLeft) = computeTimeRewards(land, blockTimestamp);
        if (reward > 0) {
            uint8 decimals = IERC20(_time).decimals();
            reward = reward * (10**decimals);
            safeTransfer(_time, owner, reward);
            uint64 tokenTimestamp = blockTimestamp - timeLeft;
            ILands(_lands).updateTokenTimestamp(owner, quadkey, landId, tokenTimestamp);

            emit ClaimRewardOfLand(owner, quadkey, landId, reward);
        }
    }

    function claimRewardOfQuadKey(address owner, string memory quadkey) public {
        bool isOwner = IQuadKey(_quadkey).isOwnerOf(owner, quadkey);
        require(isOwner, "Manager >> claimRewardOfQuadKey: not own this quadkey");

        Tokens[] memory lands = ILands(_lands).getTokensOfOwner(owner, quadkey);
        for (uint i = 0; i < lands.length; i++) {
            if (lands[i].balance > 0) {
                claimRewardOfLand(owner, quadkey, lands[i].id);
            }
        }
    }

    function claimAllRewards(address owner) public {
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20_TRANSFER_FROM_SELECTOR, _supplier, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed.");
    }
}