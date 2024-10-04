// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    //errors
    error SendMoreEthToEnterRaffle();
    error RaffleEntryDenied();
    error TransferFailed();
    error UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entryFee; //entry fee to raffle
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players; //to store the participants
    uint256 private s_startTime; //stores the start time of raffle
    uint256 private immutable s_interval; //to store the duration of raffle
    address payable s_recentWinner;
    Status s_raffleStatus = Status(0);

    enum Status {
        OPEN,
        CALCULATING
    }

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed reqId);

    constructor(
        uint256 entryFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entryFee = entryFee;
        s_interval = interval;
        s_startTime = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleStatus = Status.OPEN;
    }

    function enterRaffle() public payable {
        //require(msg.value >= i_entryFee, "Not enough eth sent");
        if (msg.value < i_entryFee) {
            revert SendMoreEthToEnterRaffle();
        }
        if (s_raffleStatus != Status.OPEN) {
            revert RaffleEntryDenied();
        }
        s_players.push(payable(msg.sender));

        emit PlayerEntered(msg.sender); //anytime you change the state then you need to emit the events
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = s_raffleStatus == Status.OPEN;
        bool hasTimePassed = ((block.timestamp - s_startTime) > s_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && hasTimePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    //this function will be called when upkeep is needed
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            //throwing an error
            revert UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleStatus)
            );
        }
        pickWinner();
    }

    function pickWinner() internal {
        //check to see enough time is passed
        if ((block.timestamp - s_startTime) < s_interval) {
            revert();
        }
        s_raffleStatus = Status.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    //Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

    // this function will be called by chainlink vrf
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleStatus = Status.OPEN;
        //resetting the players array
        s_players = new address payable[](0);
        s_startTime = block.timestamp;

        //as we updated the state so emit event
        emit WinnerPicked(s_recentWinner);

        //transferring funds
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function getEntryFee() public view returns (uint256) {
        return i_entryFee;
    }

    //to get the raffle state
    function getRaffleState() public view returns (Status) {
        return s_raffleStatus;
    }

    //to get the player
    function getPlayer(uint256 playerIndex) public view returns (address) {
        return s_players[playerIndex];
    }

    function getLastTimeStamp() public view returns(uint256){
        return s_startTime;
    }


    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }
}
