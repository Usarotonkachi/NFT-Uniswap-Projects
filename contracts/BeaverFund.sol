pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BeaverFund is Ownable {
    IERC20 private _token;

    mapping(address => uint256) adrToInputMoney;

    event MetoAdded(uint256 amount);
    event rewardWithdrawn(address user, uint256 amount);

    constructor(address metaContract) {
        _token = IERC20(metaContract);
    }

    function availableReward(address user) external view returns (uint256) {
        return adrToInputMoney[user];
    }

    function addMeto(uint256 amount) external onlyOwner {
        _token.transferFrom(msg.sender, address(this), amount);

        emit MetoAdded(amount);
    }

    function distributeRewards(address[] memory users, uint256[] memory rewards)
        external
        onlyOwner
    {
        require(users.length == rewards.length, "Not the same length");
        for (uint256 i; i < users.length; i++) {
            require(rewards[i] > 0, "Reward cannot be 0");
            adrToInputMoney[users[i]] += rewards[i];
        }
    }

    function withdrawReward() external {
        require(adrToInputMoney[msg.sender] > 0, "you do not have rewards yet");
        _token.transfer(msg.sender, adrToInputMoney[msg.sender]);

        emit rewardWithdrawn(msg.sender, adrToInputMoney[msg.sender]);

        adrToInputMoney[msg.sender] = 0;
    }
}
