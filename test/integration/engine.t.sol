// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {
    VRFCoordinatorV2_5Mock
} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract TestStabeleToken is Test {
    event UserBuyToken(address indexed user, uint256 amount);
    event UserSellToken(address indexed user, uint256 amount);
    event UserBuyTickets(address indexed user, uint256 amount);

    StableToken stableToken;

    EngineConfig.EngineParams config;
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user2 = makeAddr("user23");
    RaffileEngine engine;
    uint256 buyAmount = 2 ether;

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        EngineConfig.EngineParams memory _config;
        (_config, stableToken, engine) = deploy.run();

        config = _config;

        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testStableTokenAddress() external view {
        assertEq(address(stableToken), address(engine.stableToken()));
    }

    function testRafileIdIsZero() external view {
        assertEq(engine.raffleId(), 0);
    }

    function testEntranceFee() external view {
        assertEq(engine.entranceFee(), 5e18);
    }

    function testMaxTicketsPerRound() external view {
        assertEq(engine.maxTicketsPerRound(), 10);
    }

    function testTotalLockedTokens() external view {
        assertEq(engine.totalLockedTokens(), 0);
    }

    function testKeyHash() external view {
        assertEq(engine.getKeyHash(), config.keyHash);
    }

    function testLinkToken() external view {
        assertEq(engine.getLinkToken(), config.linkToken);
    }

    function testSubscriptionId() external view {
        assertEq(engine.getSubscriptionId(), config.subId);
    }

    // testing  Buy Token

    function testRaffileBuyTokenFailedZeroEthSent() external {
        vm.prank(user2);
        vm.expectRevert(
            RaffileEngine.RaffileEngine__EthAmountCantBeZero.selector
        );
        engine.buyRaffileToken();
    }

    function testRafileBuyTokenSucced() external {
        vm.startPrank(user);
        //stableToken.transferOwnership(address(engine));

        vm.expectEmit(true, false, false, true);
        emit UserBuyToken(user, buyAmount);
        engine.buyRaffileToken{value: buyAmount}();
        vm.stopPrank();
    }

    modifier buyRaffileToken() {
        vm.prank(user);
        engine.buyRaffileToken{value: buyAmount}();

        _;
    }

    function testRaffileTokenRevertBalancezero() external {
        vm.prank(user);
        vm.expectRevert(
            RaffileEngine.RaffileEngine__RaffileTokenBalanceIsZero.selector
        );

        engine.sellRaffileToken(buyAmount);
    }

    function testRaffilesellTokenRevrInsufficientBalance() external {
        vm.prank(user);
        engine.buyRaffileToken{value: buyAmount}();

        vm.prank(user);
        vm.expectRevert(
            RaffileEngine.RaffileEngine__InsufficientBalance.selector
        );

        engine.sellRaffileToken(buyAmount * 60e18);
    }

    function testRaffleSellTokenSuccess() external {
        vm.startPrank(user);
        stableToken.approve(address(engine), buyAmount);
        engine.buyRaffileToken{value: buyAmount}();

        vm.expectEmit(true, false, false, true);
        emit UserSellToken(user, buyAmount);
        engine.sellRaffileToken(buyAmount);

        vm.stopPrank();
    }

    function testBuyTicketRevertNeedMoreTokenTobuyBig()
        external
        buyRaffileToken
    {
        vm.prank(user);
        vm.expectRevert(
            RaffileEngine
                .RaffileEngine__InsufficientBalanceBuyMoreToken
                .selector
        );
        engine.buyTickets(buyAmount * 50e18);
    }

    function testBuyTicketRevertTokenToSmall() external buyRaffileToken {
        vm.prank(user);
        vm.expectRevert(
            RaffileEngine.RaffileEngine__InsufficientTokenToBuyTicket.selector
        );
        engine.buyTickets(1e5);
    }

    /*//////////////////////////////////////////////////////////////
                        BUY TICKET SUCCESS
    //////////////////////////////////////////////////////////////*/

    function testBuyTickSucces() external buyRaffileToken {
        // Test Scenario:
        // 1. User approves engine to spend tokens.
        // 2. User buys tickets worth 15 Token.
        // 3. Ticket Cost = 5 Token.
        // 4. Expected: User receives 3 Tickets (15/5).

        vm.prank(user);
        stableToken.approve(address(engine), 15e18);

        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit UserBuyTickets(user, 3);
        engine.buyTickets(15e18);
        console.log(engine.ticketBalance(user), "balance is here");

        assertEq(engine.ticketBalance(user), 3);
        assertEq(engine.totalTicketCost(), 15e18);
        assertEq(engine.totalLockedTokens(), 15e18);
    }

    modifier buyTickets() {
        vm.startPrank(user);

        engine.buyRaffileToken{value: buyAmount}();
        console.log(engine.ticketBalance(user), "balance is here");

        stableToken.approve(address(engine), 1500e18);
        engine.buyTickets(15e18);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        RAFFLE ENTRY LOGIC
    //////////////////////////////////////////////////////////////*/

    function testEnterRaffleSuccessed() external buyTickets {
        // Test Scenario:
        // 1. User buys LOTS of tickets (200 Tickets).
        // 2. User enters raffle with 5 Tickets.
        // 3. Logic: Range assigned should be [1, 5] since it's the first entry.
        // 4. Expected: roundRanges[0] = {start: 1, end: 5, owner: user}.

        engine.buyTickets(1000e18);
        console.log(engine.ticketBalance(user));
        engine.enterRaffle(5);
        (uint256 start, uint256 end, address owner) = engine.roundRanges(0, 0);

        assertEq(start, 1);
        assertEq(end, 5);
        assertEq(user, owner);

        vm.stopPrank();
    }

    //this did revert but chainklink more did not revert the whole tx that why it failing

    // function testFullFellRanmdomWordRevertNoPlayers() external {
    //     vm.startPrank(user);

    //     engine.buyRaffileToken{value: buyAmount}();
    //     engine.requestRandomWords();

    //     //vm.expectRevert(RaffileEngine.RaffileEngine__NoPlayers.selector);
    //     // VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(uint256(engine.s_requestId()), address(engine));

    //     console.log("called");
    //     vm.stopPrank();
    // }

    /*//////////////////////////////////////////////////////////////
                        VRF & WINNER SELECTION
    //////////////////////////////////////////////////////////////*/

    function testRequetRandomWordsSucced() external {
        // Test Scenario: Full Round Lifecycle
        // 1. User enters raffle.
        // 2. Automation triggers performUpkeep().
        // 3. engine calls VRF Coordinator to request random words.
        // 4. Mock VRF Coordinator fulfills request with a random number.
        // 5. Engine picks winner based on random number.

        vm.startPrank(user);

        engine.buyRaffileToken{value: buyAmount}();
        stableToken.approve(address(engine), 1500e18);
        engine.buyTickets(20e18);
        console.log(engine.ticketBalance(user));
        engine.enterRaffle(1);

        console.log(engine.s_requestId(), "req Id");
        console.log(engine.randomword(), "value of random");

        // Act: Simulate time passing and trigger upkeep
        vm.recordLogs();
        vm.warp(block.timestamp + 40);
        vm.roll(4);
        engine.performUpkeep("");
        Vm.Log[] memory enteries = vm.getRecordedLogs();

        // Capture requestId from event logs
        bytes32 requestId = enteries[1].topics[1];

        // MOCK Chainlink Node Response
        // We manually call fulfillRandomWords acting as the Chainlink Oracle
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(engine)
        );
        assertEq(engine.roundWinner(0), user);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        REWARD CLAIMING
    //////////////////////////////////////////////////////////////*/

    function testClaimRewardRevertRoundWinnerNotSet() external {
        // Scenario: Trying to claim reward for a round that hasn't finished.
        // Expected: Revert with RoundWinnerNotSet.
        vm.prank(user);
        vm.expectRevert(
            RaffileEngine.RaffileEngine__RoundWinnerNotSet.selector
        );
        engine.claimRewardWon(1);
    }

    function testClaimRewardRevertNotRoundWinner() external buyTickets {
        // Scenario: User A wins, User B (attacker) tries to claim.
        // Expected: Revert with YouAreNotTheWinner.

        engine.buyTickets(20e18);
        console.log(engine.ticketBalance(user));
        engine.enterRaffle(1);
        
       vm.warp(block.timestamp + 30);

console.log(engine.ticketBalance(user));

        engine.performUpkeep("");

        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(
            uint256(engine.s_requestId()),
            address(engine)
        );

        vm.stopPrank();

        vm.prank(address(500));

        vm.expectRevert(
            RaffileEngine.RaffileEngine__YouAreNotTheWinner.selector
        );
        engine.claimRewardWon(0);
    }

    function testClaimRewardSuccessed() external buyTickets {
        // Scenario: Happy Path
        // 1. User wins round.
        // 2. User claims reward.
        // 3. Expected: User balance increases by prize pool amount.
        // 4. Expected: Prize pool resets to 0.

        engine.buyTickets(20e18);
        console.log(engine.ticketBalance(user));
        uint256 userBalanceb4 = stableToken.balanceOf(user);

        engine.enterRaffle(1);
        vm.warp(block.timestamp + 40);

        engine.performUpkeep("");

        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(
            uint256(engine.s_requestId()),
            address(engine)
        );
        uint256 amountWon = engine.roundPrizePool(0);

        engine.claimRewardWon(0);
        console.log(amountWon, "amount");
        uint256 balanceAfer = stableToken.balanceOf(user);

        vm.stopPrank();
        assertEq(balanceAfer, userBalanceb4 + amountWon);
        assertEq(engine.roundPrizePool(0), 0);
        assertEq(engine.rewardClaimed(0), true);

        // Security Check: Replay Attack
        // Scenario: User tries to claim the same reward twice.
        // Expected: Revert with RewardAlreadyClaimed.
        vm.prank(user);
        vm.expectRevert(
            RaffileEngine.RaffileEngine__RewardAlreadyClaimed.selector
        );

        engine.claimRewardWon(0);
    }
}
