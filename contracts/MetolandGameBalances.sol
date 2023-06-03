pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetolandGameBalances is Ownable {
    IERC20 private _token;
    IERC721 private _tokenNFT;
    address private signer;
    //string private secretWord;

    mapping(address => uint256) adrToInputMoney;
    mapping(address => uint256[]) adrToInputNFTIds;
    mapping(address => mapping(uint256 => bool)) usedNonce;
    mapping(uint256 => uint256) tokenIdToTime;

    event deposited(address from, address to, uint256 payment);
    event depositedNFT(address from, address to, uint256[] NFTIds);
    event tokenWithdrawn(address user, uint256 amount, uint256 nonce);
    event nftWithdrawn(address user, uint256[] tokens);
    event Received();

    constructor(address metoContract, address nftContract) {
        _token = IERC20(metoContract);
        _tokenNFT = IERC721(nftContract);
        signer = msg.sender;
        //secretWord = "i like solidity";
    }

    /*function setSecretKey(string memory _newWord) external onlyOwner {
        secretWord = _newWord;
    }*/

    function deposit(uint256 amount) external {
        _token.transferFrom(msg.sender, address(this), amount);
        adrToInputMoney[msg.sender] += amount;
        emit deposited(msg.sender, msg.sender, amount);
    }

    function depositFor(address user, uint256 amount) external {
        _token.transferFrom(msg.sender, address(this), amount);
        adrToInputMoney[user] += amount;
        emit deposited(msg.sender, user, amount);
    }

    function depositNFT(uint256[] memory tokens) external {
        for (uint256 i; i < tokens.length; i++) {
            _tokenNFT.transferFrom(msg.sender, address(this), tokens[i]);
            adrToInputNFTIds[msg.sender].push(tokens[i]);
            tokenIdToTime[tokens[i]] = block.timestamp;
        }

        emit depositedNFT(msg.sender, msg.sender, adrToInputNFTIds[msg.sender]);
    }

    function getBalance(address user) external view returns (uint256) {
        return adrToInputMoney[user];
    }

    function getBalanceNFT(address user)
        external
        view
        returns (uint256[] memory)
    {
        return adrToInputNFTIds[user];
    }

    function changeSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function withdraw(
        uint256 amount,
        address user,
        uint256 nonce,
        uint256 timestamp,
        bytes memory _sig
    ) external {
        require(msg.sender == user, "Only user can withdraw own money");
        require(
            block.timestamp - timestamp <= 1 days,
            "Deadline 1 day is over"
        );
        require(usedNonce[user][nonce] == false, "Nonce is already used");
        bytes32 message = getMessageHash(
            user,
            address(this),
            amount,
            nonce,
            timestamp
        );
        require(verify(message, _sig), "It's not a signer");
        require(amount <= adrToInputMoney[user], "Not enough tokens");
        address adr = msg.sender;
        _token.transfer(user, amount);
        adrToInputMoney[adr] -= amount;
        usedNonce[user][nonce] = true;
        emit tokenWithdrawn(user, amount, nonce);
    }

    function removeNFT(uint256[] memory tokens) external {
        for (uint256 i; i < tokens.length; i++) {
            require(
                isInArray(adrToInputNFTIds[msg.sender], tokens[i]),
                "You didn't deposit these nfts"
            );
            require(
                block.timestamp - tokenIdToTime[tokens[i]] > 1 days,
                "You cannot withdraw the nft before 24 hours after depositing"
            );
            _tokenNFT.transferFrom(address(this), msg.sender, tokens[i]);
            //adrToInputNFTIds[msg.sender].push(tokens[i]);
            for (uint256 j; j < adrToInputNFTIds[msg.sender].length; j++) {
                if (adrToInputNFTIds[msg.sender][j] == tokens[i]) {
                    remove(j, msg.sender);
                }
            }
        }
        emit nftWithdrawn(msg.sender, tokens);
    }

    function isInArray(uint256[] memory Ids, uint256 id)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < Ids.length; i++) {
            if (Ids[i] == id) {
                return true;
            }
        }
        return false;
    }

    function remove(uint256 index, address user)
        internal
        returns (uint256[] memory)
    {
        //if (index >= adrToIds[msg.sender].length) return ;

        for (uint256 i = index; i < adrToInputNFTIds[user].length - 1; i++) {
            adrToInputNFTIds[user][i] = adrToInputNFTIds[user][i + 1];
        }
        delete adrToInputNFTIds[user][adrToInputNFTIds[user].length - 1];
        adrToInputNFTIds[user].pop();
        return adrToInputNFTIds[user];
    }

    function changeNFTAndMetoAddresses(address newMeto, address newNFT)
        external
        onlyOwner
    {
        _token = IERC20(newMeto);
        _tokenNFT = IERC721(newNFT);
    }

    function ownerWithdrawBNB(address to, uint256 amount) external onlyOwner {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function ownerWithdrawERC20(address to, uint256 amount) external onlyOwner {
        _token.transfer(to, amount);
    }

    function ownerWithdrawNFT(address to, uint256 tokenId) external onlyOwner {
        _tokenNFT.transferFrom(address(this), to, tokenId);
    }

    // Проверка
    function verify(bytes32 message, bytes memory _sig)
        public
        view
        returns (
            bool /*, address adr1, address adr2*/
        )
    {
        //bytes32 messageHash = getMessageHash(msg.sender, address(this), amount, nonce, timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);

        return (recover(ethSignedMessageHash, _sig) == signer); /*, recover(ethSignedMessageHash, _sig), signer*/
    }

    function getMessageHash(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, amount, nonce, timestamp));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature name");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
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
