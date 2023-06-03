//SPDX-License-Identifier: UNLICENSED

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract SPOODEEMOON is ERC721A, Ownable {
    using SafeMath for uint256;

    string private baseTokenURI;

    uint256 public publicSalePrice;

    uint256 private totalNFTs;

    mapping(address => uint256) public NFTtracker;

    mapping(uint256 => level) levelInfo;
    uint256 curLevel;

    struct level {
        bool isActive;
        uint256 totalSupply;
        uint256 minted;
    }

    mapping(address => refs) referals;
    mapping(address => mapping(uint256 => address[])) adrToLevelToRefs;

    uint256 internal refLevel1Percent;
    uint256 internal refLevel2Percent;
    uint256 internal refLevel3Percent;

    struct refs {
        address ref1;
        address ref2;
        address ref3;
        uint256 nftByRefs;
        uint256 nftCycle10;
    }

    mapping(address => allrefs[]) adrToAllRefInfo;

    struct allrefs {
        address ref;
        uint256 refLevel;
    }

    uint256 public NFTLimitPublic;

    uint256 public maxNFTs;

    event BaseURIChanged(string baseURI);

    event PublicSaleMint(address mintTo, uint256 tokensCount);

    event Received();

    address founderAddress;

    mapping(address => bool) registeredUsers;

    mapping(address => claim[]) claimInfo;
    mapping(address => uint256) public adrToClaimAmount;
    mapping(address => uint256) public adrToUsedClaimAmount;

    bool rewardAvailable;

    struct claim {
        address user;
        uint256 nftAmount;
        uint256[] nftIds;
        uint256 startTime;
        uint256 lockTime;
        uint256 percent;
        uint256 floor;
    }

    mapping(address => bool) isAdmin;
    address[] admins;

    constructor(
        string memory baseURI,
        address _founderAddress,
        uint256 lvl1,
        uint256 lvl2,
        uint256 lvl3
    ) ERC721A("NAME of Token", "SPDM symbol of token", 100, 10000) {
        baseTokenURI = baseURI;

        founderAddress = _founderAddress;

        totalNFTs = 0;

        NFTLimitPublic = 5;

        levelInfo[1].totalSupply = lvl1;
        levelInfo[2].totalSupply = lvl2;
        levelInfo[3].totalSupply = lvl3;

        maxNFTs = lvl1 + lvl2 + lvl3;
        publicSalePrice = 50000000000000000;
        //100000000000000000
        //100000000000000000
        //100000000000000000

        refLevel1Percent = 20;
        refLevel2Percent = 10;
        refLevel3Percent = 5;
        registeredUsers[founderAddress] = true;
    }

    function setPrices(uint256 _newPublicSalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
    }

    function setNFTLimits(uint256 _newLimitPublic) public onlyOwner {
        NFTLimitPublic = _newLimitPublic;
    }

    function setNFTHardcap(uint256 _newMax) public onlyOwner {
        maxNFTs = _newMax;
    }

    function registerInSystem(address referal) external {
        require(
            registeredUsers[referal] == true,
            "referal address is not registered"
        );
        require(referal != msg.sender, "You cannot be referal of yourself");
        registeredUsers[msg.sender] = true;
        if (referal != msg.sender) {
            referals[msg.sender].ref1 = referal;
            adrToLevelToRefs[referal][1].push(msg.sender);
            if (referals[referal].ref1 != address(0x0)) {
                referals[msg.sender].ref2 = referals[referal].ref1;
                adrToLevelToRefs[referals[referal].ref1][2].push(msg.sender);
                if (referals[referal].ref2 != address(0x0)) {
                    referals[msg.sender].ref3 = referals[referal].ref2;
                    adrToLevelToRefs[referals[referal].ref2][3].push(
                        msg.sender
                    );
                }
            }
        }
    }

    function freeMint() external {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(totalNFTs + 1 <= maxNFTs, "Exceeded max NFTs amount");
        require(
            levelInfo[curLevel].minted + 1 <= levelInfo[curLevel].totalSupply,
            "Exceeded max NFTs amount in this level"
        );
        require(levelInfo[curLevel].isActive, "Level is not active");
        require(
            referals[msg.sender].nftCycle10 > 9,
            "Not enough nfts minted with your referal"
        );

        _safeMint(msg.sender, 1, true, "");

        totalNFTs += 1;

        NFTtracker[msg.sender] += 1;

        levelInfo[curLevel].minted += 1;

        if (levelInfo[curLevel].minted == levelInfo[curLevel].totalSupply) {
            levelInfo[curLevel].isActive = false;
        }

        referals[msg.sender].nftCycle10 -= 10;
    }

    function PublicMint(uint256 quantity) external payable {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");
        require(
            levelInfo[curLevel].minted + quantity <=
                levelInfo[curLevel].totalSupply,
            "Exceeded max NFTs amount in this level"
        );
        require(levelInfo[curLevel].isActive, "Level is not active");

        require(
            NFTtracker[msg.sender] + quantity <= NFTLimitPublic,
            "Minting would exceed wallet limit"
        );

        require(
            msg.value >= publicSalePrice * quantity,
            "Fund amount is incorrect"
        );

        _safeMint(msg.sender, quantity, true, "");

        totalNFTs += quantity;

        NFTtracker[msg.sender] += quantity;

        levelInfo[curLevel].minted += quantity;

        /*if (levelInfo[curLevel].minted == levelInfo[curLevel].totalSupply) {
            levelInfo[curLevel].isActive = false;
            if (curLevel == 3) {
                isAllOver = true;
            }
        }*/

        uint256 money = msg.value;

        if (referals[msg.sender].ref1 != address(0x0)) {
            _widthdraw(
                referals[msg.sender].ref1,
                (msg.value * refLevel1Percent) / 100
            );
            money -= (msg.value * refLevel1Percent) / 100;

            referals[referals[msg.sender].ref1].nftByRefs += quantity;
            referals[referals[msg.sender].ref1].nftCycle10 += quantity;
            adrToAllRefInfo[referals[msg.sender].ref1].push(
                allrefs(msg.sender, 1)
            );

            if (referals[msg.sender].ref2 != address(0x0)) {
                _widthdraw(
                    referals[msg.sender].ref2,
                    (msg.value * refLevel2Percent) / 100
                );
                money -= (msg.value * refLevel2Percent) / 100;

                referals[referals[msg.sender].ref2].nftByRefs += quantity;
                referals[referals[msg.sender].ref2].nftCycle10 += quantity;
                adrToAllRefInfo[referals[msg.sender].ref2].push(
                    allrefs(msg.sender, 2)
                );
                if (referals[msg.sender].ref3 != address(0x0)) {
                    _widthdraw(
                        referals[msg.sender].ref3,
                        (msg.value * refLevel3Percent) / 100
                    );
                    money -= (msg.value * refLevel3Percent) / 100;

                    referals[referals[msg.sender].ref3].nftByRefs += quantity;
                    referals[referals[msg.sender].ref3].nftCycle10 += quantity;
                    adrToAllRefInfo[referals[msg.sender].ref3].push(
                        allrefs(msg.sender, 3)
                    );
                }
            }
        }

        _widthdraw(founderAddress, money);
    }

    function Airdrop(uint256 quantity, address wallet)
        external
        payable
        onlyOwner
    {
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");

        require(quantity <= 150, "Exceeded max transaction amount");

        _safeMint(wallet, quantity, true, "");

        totalNFTs += quantity;

        NFTtracker[wallet] += quantity;
    }

    /*function stakeNFTs(uint256[] memory tokenIds) external {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(levelInfo[curLevel].isActive, "Level is not active");
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "You are not owner of these nfts"
            );
        }

        for (uint256 i; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            if (curLevel == 1) {
                claimInfo[msg.sender].amount1++;
                levelInfo[1].staked++;
            } else if (curLevel == 2) {
                claimInfo[msg.sender].amount2++;
                levelInfo[2].staked++;
            } else if (curLevel == 3) {
                claimInfo[msg.sender].amount3++;
                levelInfo[3].staked++;
            } else if (curLevel == 4) {
                claimInfo[msg.sender].amount4++;
                levelInfo[4].staked++;
            }
            claimInfo[msg.sender].myIds.push(tokenIds[i]);
        }
    }*/

    function checkReferals(
        address user,
        uint256 refLevel,
        uint256 startPoint,
        uint256 amount
    ) external view returns (address[8] memory) {
        address[8] memory adrArray;
        uint256 count;
        for (uint256 i = startPoint; i < startPoint + amount; i++) {
            adrArray[count] = adrToLevelToRefs[user][refLevel][i];
            count++;
        }
        return adrArray;
    }

    function allowUser(
        uint256[] memory tokenIds,
        uint256 floor,
        uint256 time,
        uint256 perc,
        address user1
    ) external {
        require(
            msg.sender == owner() || isAdmin[msg.sender],
            "Not enough rights"
        );
        require(registeredUsers[user1], "Not registered in system");

        adrToClaimAmount[user1]++;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                this.ownerOf(tokenIds[i]) == user1,
                "This user is not owner of the nft"
            );
        }

        claimInfo[user1].push(
            claim(user1, tokenIds.length, tokenIds, 0, time, perc, floor)
        );

        /*
        claimInfo[user1][adrToClaimAmount[user1]].floor = floor;
        claimInfo[user1][adrToClaimAmount[user1]].lockTime = time;
        //claimInfo[user1][adrToClaimAmount[user1]].startTime = block.timestamp;
        claimInfo[user1][adrToClaimAmount[user1]].percent = perc;
        claimInfo[user1][adrToClaimAmount[user1]].user = user1;
        claimInfo[user1][adrToClaimAmount[user1]].nftAmount = tokenIds.length;*/
    }

    function stake() external {
        require(registeredUsers[msg.sender], "Not registered in system");

        require(
            adrToUsedClaimAmount[msg.sender] < adrToClaimAmount[msg.sender],
            "Don't have stakes"
        );
        require(
            claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]].nftAmount >
                0,
            "Do not have stakes at all"
        );

        for (
            uint256 i;
            i <
            claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
                .nftIds
                .length;
            i++
        ) {
            require(
                ownerOf(
                    claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
                        .nftIds[i]
                ) == msg.sender,
                "This user is not owner of the nft"
            );

            safeTransferFrom(
                msg.sender,
                address(this),
                claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]].nftIds[
                    i
                ]
            );
        }
        claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
            .startTime = block.timestamp;
        adrToUsedClaimAmount[msg.sender]++;
    }

    function checkClaimInfo(address user, uint256 claimNumber)
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 floor,
            uint256 percent,
            uint256 startTime,
            uint256 timeAvailable
        )
    {
        return (
            claimInfo[user][claimNumber - 1].nftIds,
            claimInfo[user][claimNumber - 1].floor,
            claimInfo[user][claimNumber - 1].percent,
            claimInfo[user][claimNumber - 1].startTime,
            claimInfo[user][claimNumber - 1].startTime +
                claimInfo[user][claimNumber - 1].lockTime
        );
    }

    function unStakeNFTs(uint256 numberClaim) public {
        require(numberClaim != 0, "Not correct number");
        numberClaim -= 1;
        require(registeredUsers[msg.sender], "Not registered in system");
        require(
            claimInfo[msg.sender][numberClaim].startTime +
                claimInfo[msg.sender][numberClaim].lockTime <
                block.timestamp,
            "Wait for ending of your deadline"
        );
        for (
            uint256 i;
            i < claimInfo[msg.sender][numberClaim].nftIds.length;
            i++
        ) {
            this.safeTransferFrom(
                address(this),
                msg.sender,
                claimInfo[msg.sender][numberClaim].nftIds[i]
            );
        }
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
        //if (index >= adrToIds[msg.sender].length) return ;

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

    function setRewardAmount() external payable onlyOwner {
        rewardAvailable = true;
    }

    function getRewardsAndNFTs(uint256 numberClaim) external {
        getRewards(numberClaim);
        unStakeNFTs(numberClaim);
    }

    function getRewards(uint256 numberClaim) public {
        require(numberClaim != 0, "Not correct number");
        numberClaim -= 1;
        require(registeredUsers[msg.sender], "Not registered in system");
        //require(isAllOver, "Wait for ending of 3rd session");
        require(rewardAvailable, "Admin didn't set rewardSumm yet");
        require(
            claimInfo[msg.sender][numberClaim].startTime +
                claimInfo[msg.sender][numberClaim].lockTime <
                block.timestamp,
            "Wait for ending of your deadline"
        );
        require(
            adrToUsedClaimAmount[msg.sender] <= adrToClaimAmount[msg.sender],
            "Don't have stakes"
        );
        require(
            claimInfo[msg.sender][numberClaim].startTime > 0,
            "Stake at first"
        );

        //percent 500000 = 5%

        //uint allTime = claimInfo[msg.sender][numberClaim].startTime + claimInfo[msg.sender][numberClaim].lockTime
        /*uint256 day = claimInfo[msg.sender][numberClaim].lockTime / 1 days;
        uint256 hour = (claimInfo[msg.sender][numberClaim].lockTime -
            day *
            1 days) / 1 hours;
        uint256 minute = (claimInfo[msg.sender][numberClaim].lockTime -
            hour *
            1 hours) / 1 minutes;
        uint256 fullPercent = claimInfo[msg.sender][numberClaim].percent *
            day +
            (claimInfo[msg.sender][numberClaim].percent / 24) *
            hour +
            (claimInfo[msg.sender][numberClaim].percent / 24 / 60) *
            minute;*/

        uint256 divide = 1 days * 10 * 100;

        uint256 myReward = (claimInfo[msg.sender][numberClaim].floor *
            claimInfo[msg.sender][numberClaim].nftAmount *
            claimInfo[msg.sender][numberClaim].percent *
            claimInfo[msg.sender][numberClaim].lockTime) / divide;

        (bool success, ) = payable(msg.sender).call{value: myReward}("");
        require(success, "Transfer failed");
    }

    function startMintLevel(uint256 levelId) external onlyOwner {
        for (uint256 i = 1; i < 6; i++) {
            require(
                levelInfo[i].isActive == false,
                "Not all levels are false to do this"
            );
        }
        levelInfo[levelId].isActive = true;
        curLevel = levelId;
    }

    /*function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }*/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function checkMyRewards(address user, uint256 numberClaim)
        external
        view
        returns (uint256)
    {
        require(numberClaim != 0, "Not correct number");
        numberClaim -= 1;
        require(registeredUsers[user], "Not registered in system");
        //require(isAllOver, "Wait for ending of 3rd session");
        //require(rewardAvailable, "Admin didn't set rewardSumm yet");
        /*require(
            claimInfo[msg.sender][numberClaim].startTime +
                claimInfo[msg.sender][numberClaim].lockTime <
                block.timestamp,
            "Wait for ending of your deadline"
        );*/

        //percent 500000 = 5%

        //uint allTime = claimInfo[msg.sender][numberClaim].startTime + claimInfo[msg.sender][numberClaim].lockTime
        uint256 now = block.timestamp;
        if (
            claimInfo[user][numberClaim].startTime +
                claimInfo[user][numberClaim].lockTime <
            now
        ) {
            /*
            uint256 day = claimInfo[user][numberClaim].lockTime / 1 days; 
            uint256 hour = (claimInfo[user][numberClaim].lockTime -  
                day *
                1 days) / 1 hours;
            uint256 minute = (claimInfo[user][numberClaim].lockTime -
                hour *
                1 hours - day * 1 days) / 1 minutes;
            uint256 fullPercent = claimInfo[user][numberClaim].percent *
                day +
                (claimInfo[user][numberClaim].percent / 24) *
                hour +
                (claimInfo[user][numberClaim].percent / 24 / 60) *
                minute;*/

            //2083 000 000 000 000
            uint256 divide = 1 days * 10 * 100;

            uint256 myReward = (claimInfo[user][numberClaim].floor *
                claimInfo[user][numberClaim].nftAmount *
                claimInfo[user][numberClaim].percent *
                claimInfo[user][numberClaim].lockTime) / divide;
            return myReward;
        } else {
            /*
            uint256 day = (now -
                claimInfo[user][numberClaim].startTime) /
                1 days;
            uint256 hour = (now -
                claimInfo[user][numberClaim].startTime -
                day *
                1 days) / 1 hours;
            uint256 minute = (now -
                claimInfo[user][numberClaim].startTime -
                hour *
                1 hours - day * 1 days) / 1 minutes;
            uint256 fullPercent = claimInfo[user][numberClaim].percent *
                day +
                (claimInfo[user][numberClaim].percent / 24) *
                hour +
                (claimInfo[user][numberClaim].percent / 24 / 60) *
                minute;*/

            uint256 divide = 1 days * 10 * 100;

            uint256 myReward = (claimInfo[user][numberClaim].floor *
                claimInfo[user][numberClaim].nftAmount *
                claimInfo[user][numberClaim].percent *
                (block.timestamp - claimInfo[user][numberClaim].startTime)) /
                divide;
            return myReward;
        }
    }

    /*
    function checkStakedNFTs(address user)
        external
        view
        returns (
            uint256 lv1,
            uint256 lv2,
            uint256 lv3,
            uint256 lv4
        )
    {
        return (
            claimInfo[user].amount1,
            claimInfo[user].amount2,
            claimInfo[user].amount3,
            claimInfo[user].amount4
        );
    }   */

    function userNFTIds(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function checkLevelInfo(uint256 levelId)
        external
        view
        returns (level memory)
    {
        return levelInfo[levelId];
    }

    function checkReferalPercents()
        external
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3
        )
    {
        return (refLevel1Percent, refLevel2Percent, refLevel3Percent);
    }

    function getMyChildReferalsInfo(address user)
        external
        view
        returns (
            allrefs[] memory,
            uint256 totalReferalNFT,
            uint256 cycleReferalNFT
        )
    {
        return (
            adrToAllRefInfo[user],
            referals[user].nftByRefs,
            referals[user].nftCycle10
        );
    }

    function getMyParentReferalsInfo(address user)
        external
        view
        returns (
            address ref1,
            address ref2,
            address ref3
        )
    {
        return (referals[user].ref1, referals[user].ref2, referals[user].ref3);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory _tokenURI = super.tokenURI(tokenId);

        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;

        emit BaseURIChanged(baseURI);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "Insufficent balance");

        _widthdraw(founderAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");

        require(success, "Failed to widthdraw Ether");
    }

    function changeFounderAddress(address adr) external onlyOwner {
        founderAddress = adr;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }
}
