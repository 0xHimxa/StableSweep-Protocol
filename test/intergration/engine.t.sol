// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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
        vm.expectRevert(RaffileEngine.RaffileEngine__EthAmountCantBeZero.selector);
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
        vm.expectRevert(RaffileEngine.RaffileEngine__RaffileTokenBalanceIsZero.selector);

        engine.sellRaffileToken(buyAmount);
    }

    function testRaffilesellTokenRevrInsufficientBalance() external {
        vm.prank(user);
        engine.buyRaffileToken{value: buyAmount}();

        vm.prank(user);
        vm.expectRevert(RaffileEngine.RaffileEngine__InsufficientBalance.selector);

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

    function testBuyTicketRevertNeedMoreTokenTobuyBig() external buyRaffileToken {
        vm.prank(user);
        vm.expectRevert(RaffileEngine.RaffileEngine__InsufficientBalanceBuyMoreToken.selector);
        engine.buyTickets(buyAmount * 50e18);
    }

    function testBuyTicketRevertTokenToSmall() external buyRaffileToken {
        vm.prank(user);
        vm.expectRevert(RaffileEngine.RaffileEngine__InsufficientTokenToBuyTicket.selector);
        engine.buyTickets(1e5);
    }

    function testBuyTickSucces() external buyRaffileToken {
        vm.prank(user);
        stableToken.approve(address(engine), 15e18);

        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit UserBuyTickets(user, 3);
        engine.buyTickets(15e18);
        console.log(engine.ticketBalance(user), "balance is here");

        assertEq(engine.ticketBalance(user), 3);
        assertEq(engine.roundPrizePool(0), 15e18);
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

    function testEnterRaffleRevertTicketUseZero() external buyTickets {
        console.log(stableToken.balanceOf(user), "balance is here HD");

        vm.expectRevert(RaffileEngine.RaffileEngine__TicketToUseCantBeZero.selector);
        engine.enterRaffle(0);

        vm.stopPrank();
    }

    function testEnterRaffleRevertTicketUseMorethanHave() external buyTickets {
        vm.expectRevert(RaffileEngine.RaffileEngine__InsufficientTicketBalance.selector);
        engine.enterRaffle(4);

        vm.stopPrank();
    }

    function testEnterRaffleRevertUsingMorethatMax() external buyTickets {
        engine.buyTickets(1000e18);
        vm.expectRevert(RaffileEngine.RaffileEngine__TicketExeedMaxAllowedPerRound.selector);
        engine.enterRaffle(11);

        vm.stopPrank();
    }

    function testEnterRaffleSuccessed() external buyTickets {
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
    //     VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(uint256(engine.s_requestId()), address(engine));

    //     console.log("called");
    //     vm.stopPrank();
    // }

    function testRequetRandomWordsSucced() external {
        vm.startPrank(user);

        engine.buyRaffileToken{value: buyAmount}();
        stableToken.approve(address(engine), 1500e18);
        engine.buyTickets(20e18);
        console.log(engine.ticketBalance(user));
        engine.enterRaffle(1);

        console.log(engine.s_requestId(), "req Id");
        console.log(engine.randomword(), "value of random");

        //Act
        vm.recordLogs();
        vm.roll(4);
        engine.requestRandomWords();
        Vm.Log[] memory enteries = vm.getRecordedLogs();

        bytes32 requestId = enteries[1].topics[1];

        // tho the requestId can be gooten from my contract it the s_requestId change the logic

        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(uint256(requestId), address(engine));
        assertEq(engine.roundWinner(0), user);
        vm.stopPrank();
    }

    function testClaimRewardRevertRoundWinnerNotSet() external {
        vm.prank(user);
        vm.expectRevert(RaffileEngine.RaffileEngine__RoundWinnerNotSet.selector);
        engine.claimRewardWon(1);
    }

    function testClaimRewardRevertNotRoundWinner() external buyTickets {
        engine.buyTickets(20e18);
        console.log(engine.ticketBalance(user));
        engine.enterRaffle(1);

        engine.requestRandomWords();

        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(uint256(engine.s_requestId()), address(engine));

        vm.stopPrank();

        vm.prank(address(500));

        vm.expectRevert(RaffileEngine.RaffileEngine__YouAreNotTheWinner.selector);
        engine.claimRewardWon(0);
    }

    function testClaimRewardSuccessed() external buyTickets {
        engine.buyTickets(20e18);
        console.log(engine.ticketBalance(user));
        uint256 userBalanceb4 = stableToken.balanceOf(user);

        engine.enterRaffle(1);

        engine.requestRandomWords();

        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(uint256(engine.s_requestId()), address(engine));
        uint256 amountWon = engine.roundPrizePool(0);

        engine.claimRewardWon(0);
        console.log(amountWon, "amount");
        uint256 balanceAfer = stableToken.balanceOf(user);

        vm.stopPrank();
        assertEq(balanceAfer, userBalanceb4 + amountWon);
        assertEq(engine.roundPrizePool(0), 0);
        assertEq(engine.rewardClaimed(0), true);

        vm.prank(user);
        vm.expectRevert(RaffileEngine.RaffileEngine__RewardAlreadyClaimed.selector);

        engine.claimRewardWon(0);
    }
}
