// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBEP20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Staking is Ownable {
    using Counters for Counters.Counter;

    IBEP20 private stakingToken;

    constructor(address _stakingToken, address adminRole) {
        stakingToken = IBEP20(_stakingToken);
        admin = adminRole;
    }

    uint256 private _shouldPaidAmount;
    uint256 private lastUpdatedTime;
    address public admin;

    enum TariffPlane {
        Days90,
        Days180,
        Days360,
        Days720
    }

    struct Rate {
        address owner;
        uint256 amount;
        uint256 rate;
        uint256 expiredTime;
        bool isClaimed;
        TariffPlane daysPlane;
    }

    mapping(address => mapping(uint256 => Rate)) private _rates;
    mapping(address => Counters.Counter) private _ratesId;
    mapping(address => uint256) private _balances;
    address[] private receivers;

    event Staked(
        uint256 id,
        address indexed owner,
        uint256 amount,
        uint256 rate,
        uint256 expiredTime
    );
    event Claimed(address indexed receiver, uint256 amount, uint256 id);
    event TokenAddressChanged(address oldAddress, address changeAddress);

    modifier amountNot0(uint256 _amount) {
        require(_amount > 0, "The amount must be greater than 0");
        _;
    }

    modifier checkTime(uint256 id) {
        timeUpdate();
        require(
            stakingEndTime(msg.sender, id) < lastUpdatedTime,
            "Token lock time has not yet expired or Id isn't correct"
        );
        _;
    }

    modifier dayIsCorrect(uint256 day) {
        require(
            day == 90 || day == 180 || day == 360 || day == 720,
            "Choose correct plane: 90/180/360/720 days"
        );
        _;
    }

    function getMyLastStakedId(address user) public view returns (uint256) {
        return _ratesId[user].current() - 1;
    }

    function calculateTime(uint256 day) internal view returns (uint256) {
        return (block.timestamp + day * 24 * 3600);
    }

    function getStakingToken() external view returns (IBEP20) {
        return stakingToken;
    }

    function getTotalSupply() public view returns (uint256) {
        return stakingToken.balanceOf(address(this)); // (10**stakingToken.decimals());
    }

    function allTokensBalanceOf(address _account)
        external
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function stakingEndTime(address _account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _rates[_account][id].expiredTime;
    }

    function getLastUpdatedTime() external view returns (uint256) {
        return lastUpdatedTime;
    }

    function earned(address receiver, uint256 id)
        private
        view
        returns (uint256)
    {
        return (_rates[receiver][id].amount * _rates[receiver][id].rate) / 1000;
    }

    function stake(
        address receiver,
        uint256 _amount,
        uint256 day
    ) external amountNot0(_amount) dayIsCorrect(day) {
        require(admin == msg.sender, "only admin can stake");
        uint256 id = _ratesId[receiver].current();
        uint256 expiredTime = calculateTime(day);
        uint256 rate = checkPlane(day);

        uint256 totalSupply = getTotalSupply();

        require(
            (_amount * rate) / 1000 <= totalSupply - _shouldPaidAmount,
            "Fund is not enough."
        );

        _rates[receiver][id] = Rate(
            receiver,
            _amount,
            rate,
            expiredTime,
            false,
            getDaysPlane(day)
        );

        receivers.push(receiver);

        uint256 reward = earned(receiver, id) + _amount;
        _shouldPaidAmount += reward;
        _balances[receiver] += reward;
        _ratesId[receiver].increment();

        stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount //* (10**stakingToken.decimals())
        );
        emit Staked(id, receiver, _amount, rate, expiredTime);
    }

    function claim(uint256 id) external checkTime(id) {
        require(!_rates[msg.sender][id].isClaimed, "Reward already claimed!");

        _rates[msg.sender][id].isClaimed = true;

        uint256 amount = _rates[msg.sender][id].amount;
        uint256 reward = earned(msg.sender, id) + amount;

        _shouldPaidAmount -= reward;
        _balances[msg.sender] -= reward;

        stakingToken.transfer(
            msg.sender,
            reward //* (10**stakingToken.decimals())
        );
        emit Claimed(msg.sender, reward, id);
    }

    function claimAll() external {
        require(admin == msg.sender, "only admin can execute the function");
        for (uint256 i; i < receivers.length; i++) {
            for (uint256 j; j < getMyLastStakedId(receivers[i]) + 1; j++) {
                if (
                    !_rates[receivers[i]][j].isClaimed &&
                    stakingEndTime(receivers[i], j) < block.timestamp
                ) {
                    _rates[receivers[i]][j].isClaimed = true;

                    uint256 amount = _rates[receivers[i]][j].amount;
                    uint256 reward = earned(receivers[i], j) + amount;

                    _shouldPaidAmount -= reward;
                    _balances[receivers[i]] -= reward;

                    stakingToken.transfer(
                        receivers[i],
                        reward //* (10**stakingToken.decimals())
                    );
                    emit Claimed(receivers[i], reward, j);
                }
            }
        }
    }

    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function checkPlane(uint256 day) internal pure returns (uint256) {
        if (day == 90) {
            return 60;
        } else if (day == 180) {
            return 150;
        } else if (day == 360) {
            return 380;
        }
        return 1000;
    }

    function getDaysPlane(uint256 day) internal pure returns (TariffPlane) {
        if (day == 90) {
            return TariffPlane.Days90;
        } else if (day == 180) {
            return TariffPlane.Days180;
        } else if (day == 360) {
            return TariffPlane.Days360;
        }
        return TariffPlane.Days720;
    }

    function timeUpdate() internal {
        lastUpdatedTime = block.timestamp;
    }

    function setTokenAddress(address changeAddress) external onlyOwner {
        emit TokenAddressChanged(address(stakingToken), changeAddress);
        stakingToken = IBEP20(changeAddress);
    }
}
