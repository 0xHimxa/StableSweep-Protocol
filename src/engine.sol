// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {StableToken} from "./StableToken.sol";

/**
 * @title RaffileEngine
 * @author ---
 * @notice Handles raffle ticket purchases, raffle entry, and winner selection
 * @dev Assumes StableToken implements buyToken and sellToken correctly
 */
contract RaffileEngine {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error RaffileEngine__EthAmountCantBeZero();
    error RaffileEngine__FailedToBuyToken();
    error RaffileEngine__RaffileTokenBalanceIsZero();
    error RaffileEngine__InsufficientBalance();
    error RaffileEngine__FailedToSellToken();
    error RaffileEngine__InsufficientTokenToBuyTicket();
    error RaffileEngine__InsufficientBalanceBuyMoreToken();
    error RaffileEngine__AlreadyJoined();
    error RaffileEngine__TicketToUseCantBeZero();
    error RaffileEngine__InsufficientTicketBalance();
    error RaffileEngine__NoPlayers();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event UserBuyToken(address indexed user, uint256 amount);
    event UserSellToken(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    StableToken public immutable stableToken;

    uint256 public raffleId;
    uint256 public entranceFee = 5e18;

    /// @notice Ticket balance per user
    mapping(address => uint256) public ticketBalance;

    /// @notice Ticket ranges per raffle round
    mapping(uint256 => TicketRange[]) public roundRanges;

    /// @notice Total tickets sold per raffle round
    mapping(uint256 => uint256) public roundTotalTickets;

    /// @notice Tracks whether a user has entered a specific round
    mapping(uint256 => mapping(address => bool)) public hasEnteredRound;

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
    constructor(address _stableTokenAddress) {
        stableToken = StableToken(_stableTokenAddress);
    }

    /*//////////////////////////////////////////////////////////////
                          TICKET PURCHASE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Converts StableToken into raffle tickets
     * @param tokenAmount Amount of StableToken user wants to spend
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

        stableToken.transferFrom(msg.sender, address(this), cost);
        ticketBalance[msg.sender] += tickets;
    }

    /*//////////////////////////////////////////////////////////////
                          RAFFLE ENTRY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enters the current raffle round using tickets
     * @param ticketsToUse Number of tickets to enter with
     */
    function enterRaffle(uint256 ticketsToUse) external {
        if (ticketsToUse == 0) {
            revert RaffileEngine__TicketToUseCantBeZero();
        }

        if (ticketBalance[msg.sender] < ticketsToUse) {
            revert RaffileEngine__InsufficientTicketBalance();
        }

        if (hasEnteredRound[raffleId][msg.sender]) {
            revert RaffileEngine__AlreadyJoined();
        }

        // Mark user as entered
        hasEnteredRound[raffleId][msg.sender] = true;

        // Consume tickets
        ticketBalance[msg.sender] -= ticketsToUse;

        // Assign ticket range
        uint256 start = roundTotalTickets[raffleId] + 1;
        uint256 end = start + ticketsToUse - 1;

        roundRanges[raffleId].push(TicketRange({start: start, end: end, owner: msg.sender}));

        // Update total tickets for the round
        roundTotalTickets[raffleId] = end;
    }

    /*//////////////////////////////////////////////////////////////
                          WINNER SELECTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Picks a raffle winner using a random number
     * @param random External random value
     * @return winner Address of winning participant
     */
    function pickWinner(uint256 random) external view returns (address) {
        uint256 total = roundTotalTickets[raffleId];
        if (total == 0) {
            revert RaffileEngine__NoPlayers();
        }

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
                return r.owner;
            }
        }

        revert("Winner not found");
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
        emit UserBuyToken(msg.sender, msg.value);

        if (!success) {
            revert RaffileEngine__FailedToBuyToken();
        }
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

        stableToken.transferFrom(msg.sender, address(this), value);
        emit UserSellToken(msg.sender, value);

        bool success = stableToken.sellToken(msg.sender, value);
        if (!success) {
            revert RaffileEngine__FailedToSellToken();
        }
    }
}
