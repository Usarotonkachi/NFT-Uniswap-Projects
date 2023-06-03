// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "./ERC721A.sol";

error ActivityOff();
error SummonExceedsMaxSupply();
error AlreadyMinted();
error InsufficientPayment();

contract IscribedFelines is ERC721A, Ownable {
    // Variables

    uint256 internal MAX_SUPPLY = 1000;
    uint256 public PAID_SUMMON_PRICE = 0.005 ether;

    address receiver1;
    address receiver2;
    address receiver3;

    uint256 public PAID_SUMMON_LIMIT = 1;

    string public baseURI;

    bool activity = true;

    mapping(address => bool) isMinted;

    event burned_(uint256 tokenId, string adr);

    // Constructor

    constructor(
        string memory baseURI_,
        address adr1,
        address adr2,
        address adr3
    ) ERC721A("IscribedFelines", "FELS", 1, 1000) {
        receiver1 = adr1;
        receiver2 = adr2;
        receiver3 = adr3;

        baseURI = baseURI_;
    }

    function changeActivityState() public onlyOwner {
        activity = !activity;
    }

    // Mint

    function mint() external payable {
        require(msg.sender == tx.origin, "No smart contract");
        require(!isMinted[msg.sender], "NFT is already minted before");
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Summon Exceeds Max Supply");
        require(msg.value >= PAID_SUMMON_PRICE, "Insufficient Payment");
        require(activity, "Activity Off");

        _safeMint(msg.sender, 1, true, "");
        isMinted[msg.sender] = true;
    }

    function burn(uint256 tokenId, string memory adr) public {
        _burn(tokenId);

        emit burned_(tokenId, adr);
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);

        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function checkUserNfts(address user) external view returns (uint[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(user));
        uint mark;
        for (uint256 i; i < balanceOf(user); i++) {
            for (uint256 j = mark + 1; j < currentIndex; j++) {
                if (ownerOf(j) == user) {
                    tokenIds[i] = j;
                    mark = j;
                    break;
                }
            }
        }
        return (tokenIds);
    }

    //5000000000000000

    // Withdraw

    function withdraw() external onlyOwner {
        uint256 state = (address(this).balance * 33) / 100;

        (bool ad1, ) = payable(receiver1).call{value: state}("");
        require(ad1);

        (bool ad2, ) = payable(receiver2).call{value: state}("");
        require(ad2);

        (bool ad3, ) = payable(receiver3).call{value: address(this).balance}(
            ""
        );
        require(ad3);
    }
}
