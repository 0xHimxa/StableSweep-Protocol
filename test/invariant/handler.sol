// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/engine.sol";
import "src/StableToken.sol";

contract Handler is Test {
    /*//////////////////////////////////////////////////////////////
                               PROTOCOL
    //////////////////////////////////////////////////////////////*/

    RaffileEngine public engine;
    StableToken public stableToken;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 constant MAX_ETH = 1_000 ether;
    uint256 constant MIN_ETH = 0.01 ether;
    uint256 constant ENTRANCE_FEE = 5e18;
    uint256 constant MAX_TICKETS_PER_ROUND = 10;

    /*//////////////////////////////////////////////////////////////
                             GHOST STATE
    //////////////////////////////////////////////////////////////*/

    // ETH that should be held by the engine
    uint256 public ghostEngineEth;

    // User-level accounting
  uint256 public depositedEth;
    mapping(address => uint256) public ticketBalance;
mapping(address => uint256) public ticketUsed;
    // Actor tracking
    address[] public actors;
    mapping(address => bool) internal seen;
uint256 public mintedAmount;


    /*//////////////////////////////////////////////////////////////
                               SETUP
    //////////////////////////////////////////////////////////////*/

    constructor(address engine_, address token_) {
        engine = RaffileEngine(payable(engine_));
        stableToken = StableToken(token_);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _track(address user) internal {
        if (!seen[user]) {
            seen[user] = true;
            actors.push(user);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          HANDLER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice ETH → raffle token
    function buyRaffileToken(uint256 ethAmount) external {

if(msg.sender == address(stableToken))return;


      ethAmount = bound(ethAmount, MIN_ETH, MAX_ETH);
    _track(msg.sender);

    vm.deal(msg.sender, ethAmount);

    // Get balance before to see exactly how many were minted
    uint256 balBefore = stableToken.balanceOf(msg.sender);
    
    vm.prank(msg.sender);
    engine.buyRaffileToken{value: ethAmount}();
    
    uint256 balAfter = stableToken.balanceOf(msg.sender);
    uint256 minted = balAfter - balBefore;

    depositedEth += ethAmount;
    mintedAmount += minted; // Only add the NEWLY minted amount
    }

    /// @notice raffle token → ETH
    function sellRaffileToken(uint256 value) external {

if(msg.sender == address(engine))return;

      // Instead of trusting your ghost variable, trust the actual token balance
    uint256 actualBalance = stableToken.balanceOf(msg.sender);
    if (actualBalance == 0) return;

    uint256 sellAmount = bound(value, 1, actualBalance);

    vm.prank(msg.sender);
    stableToken.approve(address(engine), sellAmount);
    
    vm.prank(msg.sender);
    engine.sellRaffileToken(sellAmount);

    // Update ghost state based on what was actually sold
    mintedAmount -= sellAmount;



        uint256 ethEquivalent = stableToken.convertUSDToEth(sellAmount);
        uint256 fee = (ethEquivalent * stableToken.getSellFee()) / stableToken.getFeePrecision();
        uint256 ethOut = ethEquivalent - fee;

  depositedEth -= ethOut;
    }

    /// @notice raffle token → tickets
    function buyTickets(uint256 tokenAmount) external {
        uint256 tokenBalance = stableToken.balanceOf(msg.sender);
        if (tokenBalance < ENTRANCE_FEE) return;

        tokenAmount = bound(tokenAmount, ENTRANCE_FEE, tokenBalance);
        _track(msg.sender);

vm.prank(msg.sender);
        stableToken.approve(address(engine), tokenAmount);
        vm.prank(msg.sender);
        engine.buyTickets(tokenAmount);
        uint256 tickets = tokenAmount / ENTRANCE_FEE;
        ticketBalance[msg.sender] += tickets;
    }

    /// @notice tickets → raffle entry (max 10 per round)
    function enterRaffle(uint256 tickets) external {
        uint256 available = ticketBalance[msg.sender];
        if (available == 0) return;
       uint256 userTicketPer =  ticketUsed[msg.sender];
        uint256 useTickets = bound(tickets, 1, MAX_TICKETS_PER_ROUND);
        if (useTickets > available) return;
        if((userTicketPer+ useTickets) > 10) return;
vm.prank(msg.sender);
        engine.enterRaffle(useTickets);

        ticketBalance[msg.sender] -= useTickets;
        ticketUsed[msg.sender] += useTickets;


    }

    /*//////////////////////////////////////////////////////////////
                          VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    function actorCount() external view returns (uint256) {
        return actors.length;
    }
}
