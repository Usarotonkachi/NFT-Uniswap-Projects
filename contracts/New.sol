pragma solidity ^0.8.19;

import "./IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract New is Ownable {
    IBEP20 USDT;
    IBEP20 USDC;
    address admin;

    constructor(
        address USDT_,
        address USDC_,
        address admin_
    ) {
        USDT = IBEP20(USDT_);
        USDC = IBEP20(USDC_);
        admin = admin_;
    }

    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function sendTokens(
        address[] memory adr,
        uint256[] memory sum,
        uint256 arg
    ) external {
        require(admin == msg.sender, "only admin can use the function");
        require(arg == 0 || arg == 1, "Not correct number");

        IBEP20 token;

        if (arg == 1) {
            token = USDT;
        } else {
            if (arg == 2) {
                token = USDC;
            }
        }

        for (uint256 i; i < adr.length; i++) {
            token.transferFrom(msg.sender, adr[i], sum[i]);
        }
    }
}
