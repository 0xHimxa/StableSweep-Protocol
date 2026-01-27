// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {RaffileEngine} from "src/engine.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestStableTokenFuzz is Test {
    StableToken stableToken;
    RaffileEngine engine;
    EngineConfig.EngineParams config;

    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user = makeAddr("user");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    address[] internal actors;

    uint256 constant ENTRANCE_FEE = 5 ether;
    uint256 constant MAX_ETH = 1_000 ether;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        (config, stableToken, engine) = deploy.run();

        actors.push(user);
        actors.push(user1);
        actors.push(user2);

        for (uint256 i; i < actors.length; i++) {
            vm.deal(actors[i], MAX_ETH);
        }

        vm.deal(address(engine), MAX_ETH);
      
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ: BUY TOKEN
    //////////////////////////////////////////////////////////////*/

    function testFuzz_buyRaffileToken(uint256 ethAmount, uint8 actorIndex) external {
        address actor = actors[actorIndex % actors.length];
        ethAmount = bound(ethAmount, 1 ether, MAX_ETH);

        uint256 balanceBefore = actor.balance;

        vm.prank(actor);
        engine.buyRaffileToken{value: ethAmount}();

        //buy fee
        uint256 amountUsedWorth = stableToken.getAndConvertEthPrice(ethAmount);

        uint256 fee = (amountUsedWorth * stableToken.getBuyFee()) / stableToken.getFeePrecision();
        uint256 feeRemoved = amountUsedWorth - fee;

     

        assertEq(actor.balance, balanceBefore - ethAmount);
        assertEq(address(stableToken).balance, ethAmount);
        assertEq(stableToken.balanceOf(actor), feeRemoved);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ: SELL TOKEN
    //////////////////////////////////////////////////////////////*/

    function testFuzz_sellRaffileToken(uint256 ethAmount, uint8 actorIndex) external {
        address actor = actors[actorIndex % actors.length];
        ethAmount = bound(ethAmount, 1 ether, MAX_ETH);

        vm.startPrank(actor);
        engine.buyRaffileToken{value: ethAmount}();

        uint256 tokenBalance = stableToken.balanceOf(actor);
        stableToken.approve(address(engine), tokenBalance);

        uint256 ethBefore = actor.balance;
        uint256 stableBefore = address(stableToken).balance;

        engine.sellRaffileToken(tokenBalance);
        vm.stopPrank();

        uint256 ethEquivalent = stableToken.convertUSDToEth(tokenBalance);
        uint256 fee = (ethEquivalent * stableToken.getSellFee()) / stableToken.getFeePrecision();
        uint256 ethOut = ethEquivalent - fee;

        assertEq(actor.balance, ethBefore + ethOut);
        assertEq(address(stableToken).balance, stableBefore - ethOut);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ: BUY TICKETS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_buyTickets(uint256 ethAmount, uint8 actorIndex) external {
        address actor = actors[actorIndex % actors.length];
        ethAmount = bound(ethAmount, ENTRANCE_FEE, MAX_ETH);

        vm.startPrank(actor);
        engine.buyRaffileToken{value: ethAmount}();

        stableToken.approve(address(engine), ethAmount);
        engine.buyTickets(ethAmount);
        vm.stopPrank();

        uint256 tickets = ethAmount / ENTRANCE_FEE;

        assertEq(engine.ticketBalance(actor), tickets);
        assertEq(stableToken.balanceOf(address(engine)), tickets * ENTRANCE_FEE);
    }

    /*//////////////////////////////////////////////////////////////
                    FUZZ: ENTER RAFFLE (PARTIAL)
    //////////////////////////////////////////////////////////////*/

    function testFuzz_enterRaffle(uint256 ethAmount, uint8 ticketsToUse, uint8 actorIndex) external {
        address actor = actors[actorIndex % actors.length];
        ethAmount = bound(ethAmount, ENTRANCE_FEE, MAX_ETH);

        vm.startPrank(actor);
        engine.buyRaffileToken{value: ethAmount}();
        stableToken.approve(address(engine), ethAmount);
        engine.buyTickets(ethAmount);
        vm.stopPrank();

        uint256 balanceBefore = engine.ticketBalance(actor);
        uint256 useTickets = bound(ticketsToUse, 1, balanceBefore);

        if (useTickets > 10) {
            vm.prank(actor);
            vm.expectRevert(RaffileEngine.RaffileEngine__TicketExeedMaxAllowedPerRound.selector);
            engine.enterRaffle(useTickets);
        } else {
            vm.prank(actor);
            engine.enterRaffle(useTickets);

            assertEq(engine.ticketBalance(actor), balanceBefore - useTickets);
            assertEq(engine.ticketsUsedPerRound(engine.raffleId(), actor), useTickets);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        SCENARIO: FULL ROUND
    //////////////////////////////////////////////////////////////*/

    function testScenario_fullRaffleLifecycle() external {
        uint256 totalTickets;

        for (uint256 i = 0; i < actors.length; i++) {
            address player = actors[i];

            vm.startPrank(player);
            engine.buyRaffileToken{value: 50 ether}();
            stableToken.approve(address(engine), 50 ether);
            engine.buyTickets(50 ether);

            uint256 tickets = engine.ticketBalance(player);
            uint256 enterAmount = tickets > 10 ? 10 : tickets;

            engine.enterRaffle(enterAmount);
            totalTickets += enterAmount;
            vm.stopPrank();
        }

        assertEq(engine.roundTotalTickets(engine.raffleId()), totalTickets);
        vm.startPrank(owner);
        
        vm.warp( block.timestamp + 40);
        engine.performUpkeep("");
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(uint256(engine.s_requestId()), address(engine));
        vm.stopPrank();
        address winner = engine.roundWinner(0);

        vm.prank(winner);
        engine.claimRewardWon(0);

        assertEq(engine.roundPrizePool(0), 0);
        assertEq(engine.totalLockedTokens(), 0);
        assertEq(engine.raffleId(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                            INVARIANTS
    //////////////////////////////////////////////////////////////*/
}
