//SPDX-License-Identifier: UNLICENSED

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract SPOODEEMOON2 is ERC721A, Ownable {
    using SafeMath for uint256;

    string private baseTokenURI;

    uint256 public publicSalePrice;

    uint256 private totalNFTs;

    mapping(address => uint256) public NFTtracker;

    uint256 internal refLevel1Percent;

    mapping(address => address[]) public adrToAllRefs;
    mapping(address => address) public adrToParentRef;
    mapping(address => uint256) adrToCycle;

    uint256 public NFTLimitPublic;

    uint256 public maxNFTs;

    event BaseURIChanged(string baseURI);

    event PublicSaleMint(address mintTo, uint256 tokensCount);

    event Received();

    address founderAddress;

    mapping(address => bool) registeredUsers;

    mapping(address => bool) isAdmin;
    address[] admins;

    constructor(
        string memory baseURI,
        address _founderAddress,
        uint256 maxNFT
    ) ERC721A("NAME of Token", "SPDM symbol of token", 100, 10000) {
        baseTokenURI = baseURI;

        founderAddress = _founderAddress;

        totalNFTs = 0;

        NFTLimitPublic = 5;

        maxNFTs = maxNFT;
        publicSalePrice = 50000000000000000;

        refLevel1Percent = 20;

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
        adrToParentRef[msg.sender] = referal;
        adrToAllRefs[referal].push(msg.sender);
    }

    function freeMint() external {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(totalNFTs + 1 <= maxNFTs, "Exceeded max NFTs amount");

        require(
            adrToCycle[msg.sender] > 9,
            "Not enough nfts minted with your referal"
        );

        _safeMint(msg.sender, 1, true, "");

        totalNFTs += 1;

        NFTtracker[msg.sender] += 1;

        adrToCycle[msg.sender] -= 10;
    }

    function PublicMint(uint256 quantity) external payable {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");

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

        uint256 money = msg.value;

        _widthdraw(
            adrToParentRef[msg.sender],
            (refLevel1Percent * money) / 100
        );
        money -= (refLevel1Percent * money) / 100;

        _widthdraw(founderAddress, money);
        adrToCycle[adrToParentRef[msg.sender]] += quantity;
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

    function checkReferals(
        address user,
        uint256 startPoint,
        uint256 amount
    ) external view returns (address[8] memory) {
        address[8] memory adrArray;
        uint256 count;
        for (uint256 i = startPoint; i < startPoint + amount; i++) {
            adrArray[count] = adrToAllRefs[user][i];
            count++;
        }
        return adrArray;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function userNFTIds(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function checkReferalPercent() external view returns (uint256 level1) {
        return (refLevel1Percent);
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
