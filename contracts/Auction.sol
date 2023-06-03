pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    IERC721 token;

    mapping(address => uint256) adrToEth;
    mapping(address => mapping(uint256 => uint256)) adrToLotToBlockedMoney;
    mapping(uint256 => lot) idToLotInfo;
    uint256 totalBlocked;

    uint256 allLots;

    struct lot {
        uint256 firstPrice;
        address firstBuyer;
        uint256 secondPrice;
        address secondBuyer;
        uint256 minPrice;
        uint256 nftId;
        address winner;
        uint256 time;
        uint256 startTime;
    }

    mapping(address => bool) isAdmin;
    address[] admins;

    constructor(address nftContract) {
        token = IERC721(nftContract);
    }

    function addMoney() external payable {
        adrToEth[msg.sender] += msg.value;
        totalBlocked += msg.value;
    }

    function getMoney(uint256 money) external {
        require(money <= adrToEth[msg.sender], "Not enough money on balance");
        (bool success, ) = payable(msg.sender).call{value: money}("");

        require(success, "Transfer failed");
    }

    function newLot(
        uint256 minSumm,
        uint256 time_,
        uint256 nftId_
    ) external {
        require(
            msg.sender == owner() || isAdmin[msg.sender],
            "Not enough rights"
        );

        allLots++;
        idToLotInfo[allLots].minPrice = minSumm;
        idToLotInfo[allLots].firstPrice = minSumm;
        idToLotInfo[allLots].time = time_;
        idToLotInfo[allLots].nftId = nftId_;
        idToLotInfo[allLots].startTime = block.timestamp;
        token.transferFrom(msg.sender, address(this), nftId_);
    }

    function offer(uint256 lotId, uint256 money) external {
        require(lotId <= allLots, "lot doesn't exist");
        require(
            idToLotInfo[lotId].winner == address(0),
            "Lot is closed (someone won it)"
        );
        require(
            block.timestamp <=
                idToLotInfo[lotId].time *
                    1 minutes +
                    idToLotInfo[allLots].startTime,
            "Lot is closed (time is over)"
        );

        require(
            adrToEth[msg.sender] >= money,
            "Don't have this sum in balance"
        );
        require(
            money > idToLotInfo[lotId].firstPrice,
            "Not enough money to offer"
        );

        if (idToLotInfo[lotId].secondBuyer != address(0)) {
            adrToEth[idToLotInfo[lotId].secondBuyer] += idToLotInfo[lotId]
                .secondPrice;
            adrToLotToBlockedMoney[idToLotInfo[lotId].secondBuyer][
                lotId
            ] -= idToLotInfo[lotId].secondPrice;
        }

        idToLotInfo[lotId].secondPrice = idToLotInfo[lotId].firstPrice;
        idToLotInfo[lotId].secondBuyer = idToLotInfo[lotId].firstBuyer;

        idToLotInfo[lotId].firstPrice = money;
        idToLotInfo[lotId].firstBuyer = msg.sender;

        adrToEth[msg.sender] -= money;
        adrToLotToBlockedMoney[msg.sender][lotId] += money;
    }

    function closeLot(uint256 lotId) external {
        require(
            msg.sender == owner() || isAdmin[msg.sender],
            "Not enough rights"
        );

        require(lotId <= allLots, "lot doesn't exist");
        require(
            idToLotInfo[lotId].winner == address(0),
            "Lot is closed (someone won it)"
        );
        require(
            block.timestamp >
                idToLotInfo[lotId].time *
                    1 minutes +
                    idToLotInfo[allLots].startTime,
            "time is not over)"
        );

        if (idToLotInfo[lotId].firstBuyer != address(0)) {
            adrToEth[idToLotInfo[lotId].firstBuyer] +=
                idToLotInfo[lotId].firstPrice -
                idToLotInfo[lotId].secondPrice;
            adrToLotToBlockedMoney[idToLotInfo[lotId].firstBuyer][
                lotId
            ] -= idToLotInfo[lotId].firstPrice;
            totalBlocked -= idToLotInfo[lotId].firstPrice;
            if (idToLotInfo[lotId].secondBuyer != address(0)) {
                adrToEth[idToLotInfo[lotId].secondBuyer] += idToLotInfo[lotId]
                    .secondPrice;
                adrToLotToBlockedMoney[idToLotInfo[lotId].secondBuyer][
                    lotId
                ] -= idToLotInfo[lotId].secondPrice;
            }
            token.transferFrom(
                address(this),
                idToLotInfo[lotId].firstBuyer,
                idToLotInfo[lotId].nftId
            );
            idToLotInfo[lotId].winner = idToLotInfo[lotId].firstBuyer;
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance - totalBlocked
        }("");

        require(success, "Transfer failed");
    }

    function addAdmin(address user) external onlyOwner {
        require(!isAdmin[user], "Already admin");
        isAdmin[user] = true;
        admins.push(user);
    }

    function deleteAdmin(address user) external onlyOwner {
        require(isAdmin[user], "Not admin");
        for (uint256 i; i < admins.length; i++) {
            if (admins[i] == user) {
                removeAdmin(i);
            }
        }
    }

    function removeAdmin(uint256 index) internal returns (address[] memory) {
        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    function checkAllAdmins()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return admins;
    }

    function checkBalance(address user) external view returns (uint256) {
        return adrToEth[user];
    }

    function lotInfo(uint256 lotId) external view returns (lot memory) {
        require(lotId <= allLots, "lot doesn't exist");
        return idToLotInfo[lotId];
    }

    function checkBlockedMoney(address user, uint256 lotId)
        external
        view
        returns (uint256)
    {
        return adrToLotToBlockedMoney[user][lotId];
    }

    function adminMoney() external view returns (uint256) {
        return address(this).balance - totalBlocked;
    }
}
