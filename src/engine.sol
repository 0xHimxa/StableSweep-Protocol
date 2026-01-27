// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {StableToken} from "./StableToken.sol";
import {
    LinkTokenInterface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {
    VRFConsumerBaseV2Plus
} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    IVRFCoordinatorV2Plus
} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {
    VRFV2PlusClient
} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title RaffleEngine
 * @author Himxa
 * @notice Handles raffle ticket purchases, raffle entry, and winner selection using Chainlink VRF.
 * @dev Integrates with StableToken for payments and Chainlink VRF for verifiable randomness.
 */
contract RaffileEngine is VRFConsumerBaseV2Plus {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when buying tokens with 0 ETH
    error RaffileEngine__EthAmountCantBeZero();
    /// @notice Thrown when token purchase fails
    error RaffileEngine__FailedToBuyToken();
    /// @notice Thrown when selling tokens with 0 balance
    error RaffileEngine__RaffileTokenBalanceIsZero();
    /// @notice Thrown when selling more tokens than balance
    error RaffileEngine__InsufficientBalance();
    /// @notice Thrown when token sale fails
    error RaffileEngine__FailedToSellToken();
    /// @notice Thrown when converting 0 tokens to tickets results in 0 tickets
    error RaffileEngine__InsufficientTokenToBuyTicket();
    /// @notice Thrown when user doesn't have enough tokens to buy requested tickets
    error RaffileEngine__InsufficientBalanceBuyMoreToken();
    /// @notice Thrown when user is already joined (unused in current logic but kept for safety)
    error RaffileEngine__AlreadyJoined();
    /// @notice Thrown when entering raffle with 0 tickets
    error RaffileEngine__TicketToUseCantBeZero();
    /// @notice Thrown when entering raffle with more tickets than owned
    error RaffileEngine__InsufficientTicketBalance();
    /// @notice Thrown when trying to pick winner with no players
    error RaffileEngine__NoPlayers();
    /// @notice Thrown when binary search fails to find a winner (should not happen)
    error RaffileEngine__WinnerNotFound();
    /// @notice Thrown when ticket purchase transfer fails
    error RaffileEngine__FailedToBuyTicket();
    /// @notice Thrown when trying to enter a closed raffle
    error RaffileEngine__RaffleIsClosed();
    /// @notice Thrown when exceeding max tickets per round
    error RaffileEngine__TicketExeedMaxAllowedPerRound();
    /// @notice Thrown when non-winner tries to claim reward
    error RaffileEngine__YouAreNotTheWinner();
    /// @notice Thrown when trying to claim reward before winner is set
    error RaffileEngine__RoundWinnerNotSet();
    /// @notice Thrown when reward transfer fails
    error RaffileEngine__failedToClaimReward();
    /// @notice Thrown when claiming an already claimed reward
    error RaffileEngine__RewardAlreadyClaimed();
    /// @notice Thrown when upkeep is requested but conditions are not met
    error RaffileEngine__NotYetPickingWinner();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when user buys StableToken
    event UserBuyToken(address indexed user, uint256 amount);
    /// @notice Emitted when user sells StableToken
    event UserSellToken(address indexed user, uint256 amount);
    /// @notice Emitted when user purchases tickets
    event UserBuyTickets(address indexed user, uint256 amount);
    /// @notice Emitted when user enters a raffle round
    event UserEnterRaffle(address indexed user, uint256 amount);
    /// @notice Emitted when a winner is picked for a round
    event RoundWinnerPicked(uint256 indexed roundId, address indexed winner);
    /// @notice Emitted when a winner claims their reward
    event RewardClaimed(address indexed winner, uint256 amount);
    /// @notice Emitted when Chainlink VRF is requested
    event RandomWordsRequested(uint256 indexed requestId);

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/
    enum RaffleState {
        Open,
        Closed
    }

    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    StableToken public immutable stableToken;

    uint256 public raffleId;
    uint256 public immutable entranceFee;
    uint256 public maxTicketsPerRound = 10;
    uint256 public randomword;
    RaffleState public currentState;

    /// @notice Ticket balance per user
    mapping(address => uint256) public ticketBalance;

    /// @notice Ticket ranges per raffle round
    mapping(uint256 => TicketRange[]) public roundRanges;

    /// @notice Total tickets sold per raffle round
    mapping(uint256 => uint256) public roundTotalTickets;

    /// @notice Tracks winner per round
    mapping(uint256 => address) public roundWinner;

    /// @notice Tracks tickets used by a user per round
    mapping(uint256 => mapping(address => uint256)) public ticketsUsedPerRound;

    mapping(uint256 => bool) public rewardClaimed;

    /// @notice StableToken locked per raffle round
    mapping(uint256 => uint256) public roundPrizePool;

    /// @notice Total StableToken locked across all active rounds
    uint256 public totalLockedTokens;
    uint256 public totalTicketBought;
    uint256 public totalTicketCost;
    uint256 public activeTicket;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    ///
    //chalink vrf

    LinkTokenInterface LINKTOKEN;

    // most of this hardcoded value will be removed and be passed throug  contructor instead

    //the  maximum gasfee oracle charges
    bytes32 private immutable keyHash;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 private constant callbackGasLimit = 100_000;

    // The default is 3, but you can set this higher.
    uint16 private constant requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 private constant numWords = 1;

    // Storage parameters

    uint256 public s_requestId;
    uint256 public s_subscriptionId;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct TicketRange {
        uint256 start;
        uint256 end;
        address owner;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the Raffle Engine
     * @param _stableTokenAddress Address of the StableToken contract
     * @param vrfCordinatorAddress Address of Chainlink VRF Coordinator
     * @param _keyHash Gas lane key hash
     * @param _linkTokenAddress Address of LINK token
     * @param subId Chainlink VRF Subscription ID
     * @param _interval Time interval between raffle rounds (automation)
     * @param _entranceFee Cost of one ticket in StableTokens
     */
    constructor(
        address _stableTokenAddress,
        address vrfCordinatorAddress,
        bytes32 _keyHash,
        address _linkTokenAddress,
        uint256 subId,
        uint256 _interval,
        uint256 _entranceFee
    ) VRFConsumerBaseV2Plus(vrfCordinatorAddress) {
        stableToken = StableToken(_stableTokenAddress);
        currentState = RaffleState.Open;
        s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCordinatorAddress);
        keyHash = _keyHash;

        LINKTOKEN = LinkTokenInterface(_linkTokenAddress);
        s_subscriptionId = subId;
        s_lastTimeStamp = block.timestamp;
        i_interval = _interval;
        entranceFee = _entranceFee;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                          TICKET PURCHASE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Converts StableToken into raffle tickets
     * @param tokenAmount Amount of StableToken user wants to spend
     *
     * Logic:
     * - Checks user balance.
     * - Calculates tickets: tickets = tokenAmount / entranceFee.
     * - Example: 50 Tokens / 5 Token Fee = 10 Tickets.
     */
    function buyTickets(uint256 tokenAmount) external {
        uint256 userTokenBalance = stableToken.balanceOf(msg.sender);
        if (userTokenBalance < tokenAmount) {
            revert RaffileEngine__InsufficientBalanceBuyMoreToken();
        }

        uint256 tickets = tokenAmount / entranceFee;
        if (tickets == 0) {
            revert RaffileEngine__InsufficientTokenToBuyTicket();
        }

        uint256 cost = tickets * entranceFee;
        ticketBalance[msg.sender] += tickets;

        // Transfer StableToken from user to contract
        bool success = stableToken.transferFrom(
            msg.sender,
            address(this),
            cost
        );
        if (!success) {
            revert RaffileEngine__FailedToBuyTicket();
        }
        //roundPrizePool[raffleId] += cost;
        totalTicketBought += tickets;
        totalTicketCost += cost;
        totalLockedTokens += cost;
        activeTicket += tickets;

        emit UserBuyTickets(msg.sender, tickets);
    }

    /*//////////////////////////////////////////////////////////////
                          RAFFLE ENTRY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enters the current raffle round using tickets
     * @param ticketsToUse Number of tickets to enter with
     *
     * Example Logic:
     * - Current Total Tickets: 10.
     * - User Enters with 5 Tickets.
     * - Range Assigned: [11, 15].
     * - New Total Tickets: 15.
     * - Array: TicketRange(start: 11, end: 15, owner: user).
     */
    function enterRaffle(uint256 ticketsToUse) external {
        if (currentState == RaffleState.Closed) {
            revert RaffileEngine__RaffleIsClosed();
        }

        if (ticketsToUse == 0) {
            revert RaffileEngine__TicketToUseCantBeZero();
        }

        if (ticketBalance[msg.sender] < ticketsToUse) {
            revert RaffileEngine__InsufficientTicketBalance();
        }

        ticketsUsedPerRound[raffleId][msg.sender] += ticketsToUse;

        if (ticketsUsedPerRound[raffleId][msg.sender] > maxTicketsPerRound) {
            revert RaffileEngine__TicketExeedMaxAllowedPerRound();
        }

        // Consume tickets
        ticketBalance[msg.sender] -= ticketsToUse;

        // Assign ticket range
        uint256 start = roundTotalTickets[raffleId] + 1;
        uint256 end = start + ticketsToUse - 1;
        roundPrizePool[raffleId] += ticketsToUse * entranceFee;
        activeTicket -= ticketsToUse;

        roundRanges[raffleId].push(
            TicketRange({start: start, end: end, owner: msg.sender})
        );

        // Update total tickets for the round
        roundTotalTickets[raffleId] = end;

        emit UserEnterRaffle(msg.sender, ticketsToUse);
    }

    //chain Link Automation

    /**
     * @notice Check if upkeep is needed (time passed, open state, has balance/players)
     * @return upKeepNeeded True if raffle needs to be closed and winner picked
     */
    function checkUpKeep(
        bytes memory /* callData */
    ) public view returns (bool upKeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = currentState == RaffleState.Open;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = roundTotalTickets[raffleId] > 0;
        upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        return (upKeepNeeded, "");
    }

    // vrf function implementaion

    /**
     * @notice Triggers Chainlink VRF request if upkeep is needed.
     * @dev Called by Chainlink Automation or manually.
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpKeep("");

        if (!upkeepNeeded) revert RaffileEngine__NotYetPickingWinner();

        currentState = RaffleState.Closed;

        // Will revert if subscription is not set and funded.
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RandomWordsRequested(s_requestId);
    }

    /*//////////////////////////////////////////////////////////////
                          WINNER SELECTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Callback function used by VRF Coordinator to set random number and pick winner
     * @param randomWords Random values returned by Chainlink
     *
     * Logic:
     * 1. Get random number from VRF (e.g., 987654321).
     * 2. Total Tickets = 20.
     * 3. Winning Ticket = (987654321 % 20) + 1 = 2.
     * 4. Binary Search finds which user owns ticket #2.
     * 5. Sets winner and resets round.
     */
    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    ) internal override {
        randomword = randomWords[0];

        uint256 total = roundTotalTickets[raffleId];
        if (total == 0) {
            revert RaffileEngine__NoPlayers();
        }

        uint256 random = randomWords[0];
        uint256 winningTicket = (random % total) + 1;
        TicketRange[] storage ranges = roundRanges[raffleId];

        uint256 left = 0;
        uint256 right = ranges.length - 1;

        // Binary search for winning ticket owner
        while (left <= right) {
            uint256 mid = (left + right) / 2;
            TicketRange storage r = ranges[mid];

            if (winningTicket < r.start) {
                right = mid - 1;
            } else if (winningTicket > r.end) {
                left = mid + 1;
            } else {
                roundWinner[raffleId] = r.owner;
                emit RoundWinnerPicked(raffleId, r.owner);

                _resetRaffleRound();
                return;
            }
        }

        revert RaffileEngine__WinnerNotFound();
    }

    /**
     * @dev Resets state for the next raffle round
     */
    function _resetRaffleRound() internal {
        raffleId += 1;
        currentState = RaffleState.Open;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * @notice Claims the reward for the winner of a round
     * @param _roundId The round ID to claim reward from
     */
    function claimRewardWon(uint256 _roundId) public {
        if (rewardClaimed[_roundId]) {
            revert RaffileEngine__RewardAlreadyClaimed();
        }

        address winnerAddress = roundWinner[_roundId];
        if (winnerAddress == address(0)) {
            revert RaffileEngine__RoundWinnerNotSet();
        }

        if (winnerAddress != msg.sender) {
            revert RaffileEngine__YouAreNotTheWinner();
        }
        rewardClaimed[_roundId] = true;

        uint256 amountWon = roundPrizePool[_roundId];

        roundPrizePool[_roundId] = 0;
        totalLockedTokens -= amountWon;
        // Transfer StableToken reward to winner
        bool success = stableToken.transfer(winnerAddress, amountWon);
        if (!success) {
            revert RaffileEngine__failedToClaimReward();
        }

        emit RewardClaimed(winnerAddress, amountWon);
    }

    /*//////////////////////////////////////////////////////////////
                      STABLE TOKEN EXCHANGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Buys StableToken using ETH
     */
    function buyRaffileToken() external payable {
        if (msg.value == 0) {
            revert RaffileEngine__EthAmountCantBeZero();
        }

        bool success = stableToken.buyToken{value: msg.value}(msg.sender);
        if (!success) {
            revert RaffileEngine__FailedToBuyToken();
        }

        emit UserBuyToken(msg.sender, msg.value);
    }

    /**
     * @notice Sells StableToken in exchange for ETH
     * @param value Amount of StableToken to sell
     */
    function sellRaffileToken(uint256 value) external {
        uint256 userTokenBalance = stableToken.balanceOf(msg.sender);
        if (userTokenBalance == 0) {
            revert RaffileEngine__RaffileTokenBalanceIsZero();
        }

        if (userTokenBalance < value) {
            revert RaffileEngine__InsufficientBalance();
        }

        // Transfer StableToken from user to contract
        bool successT = stableToken.transferFrom(
            msg.sender,
            address(this),
            value
        );
        if (!successT) {
            revert RaffileEngine__FailedToSellToken();
        }

        // Sell StableToken for ETH
        bool success = stableToken.sellToken(msg.sender, value);
        if (!success) {
            revert RaffileEngine__FailedToSellToken();
        }

        emit UserSellToken(msg.sender, value);
    }

    function getKeyHash() public view returns (bytes32) {
        return keyHash;
    }

    function getSubscriptionId() public view returns (uint256) {
        return s_subscriptionId;
    }

    function getLinkToken() public view returns (address) {
        return address(LINKTOKEN);
    }
}
