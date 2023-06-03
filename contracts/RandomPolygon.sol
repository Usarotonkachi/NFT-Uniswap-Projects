pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract RandomPolygon is VRFConsumerBaseV2, ConfirmedOwner {
    mapping(address => mapping(uint256 => participant[])) adrToIdToInfo;
    mapping(address => mapping(uint256 => win)) lotWinner;

    address admin;
    uint256 public numb;

    struct participant {
        address adr;
        string twitterId;
        string twitterUsername;
        string discordId;
        string discordUsername;
    }

    struct win {
        address winner;
        uint256 id;
    }

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public requests;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */
    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;
    }

    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() public returns (uint256 requestId) {
        require(msg.sender == admin, "not admin");
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getWinner(
        address lotOwner,
        uint256 lotId,
        uint256 amount
    ) external {
        require(msg.sender == admin, "not admin");
        require(lotWinner[lotOwner][lotId].winner == address(0), "Already have winner");
        uint256 random = requestRandomWords();
        random = random % amount;
        lotWinner[lotOwner][lotId].winner = adrToIdToInfo[lotOwner][lotId][
            random
        ].adr;
        lotWinner[lotOwner][lotId].id = random;
    }

    function getNumber(uint256 amount) external returns (uint256) {
        uint256 random = requestRandomWords();
        random = random % amount;
        numb = random;
        return random;
    }

    function checkNumber() external view returns (uint256) {
        return numb;
    }

    function participate(
        address adr,
        string memory twitterId,
        string memory twitterUsername,
        string memory discordId,
        string memory discordUsername,
        address lotOwner,
        uint256 lotId
    ) external {
        adrToIdToInfo[lotOwner][lotId].push(
            participant(
                adr,
                twitterId,
                twitterUsername,
                discordId,
                discordUsername
            )
        );
    }

    function isParticipated(
        address lotOwner,
        uint256 lotId,
        address adr,
        string memory twitterId,
        string memory discordId
    )
        external
        view
        returns (
            bool partAdr,
            bool partTwitter,
            bool partDiscord
        )
    {
        bool pAdr;
        bool pTw;
        bool pDis;
        for (uint256 i; i < adrToIdToInfo[lotOwner][lotId].length; i++) {
            if (adr == adrToIdToInfo[lotOwner][lotId][i].adr) {
                pAdr = true;
            }
            if (
                keccak256(abi.encodePacked(twitterId)) ==
                keccak256(
                    abi.encodePacked(
                        adrToIdToInfo[lotOwner][lotId][i].twitterId
                    )
                )
            ) {
                pTw = true;
            }
            if (
                keccak256(abi.encodePacked(discordId)) ==
                keccak256(
                    abi.encodePacked(
                        adrToIdToInfo[lotOwner][lotId][i].discordId
                    )
                )
            ) {
                pDis = true;
            }
        }
        return (pAdr, pTw, pDis);
    }

    function giveawayParticipantsCount(address lotOwner, uint256 lotId)
        external
        view
        returns (uint256 count, address winner)
    {
        return (
            adrToIdToInfo[lotOwner][lotId].length,
            lotWinner[lotOwner][lotId].winner
        );
    }

    function giveawaysParticipantsCount(
        address lotOwner,
        uint256[] memory array
    ) external view returns (uint256[] memory maxParticipants) {
        uint256[] memory IdArray = new uint256[](array.length);
        for (uint256 i; i < array.length; i++) {
            IdArray[i] = adrToIdToInfo[lotOwner][array[i]].length;
        }
        return IdArray;
    }
}
