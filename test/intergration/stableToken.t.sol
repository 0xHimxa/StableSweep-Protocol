// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {RaffileEngine} from "src/engine.sol";

contract TestStabeleToken is Test {
    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    StableToken stableToken;
    RaffileEngine eng;

    EngineConfig.EngineParams config;

    // Test users
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user1 = makeAddr("user12");
    address user2 = makeAddr("user23");

    // Common test amount
    uint256 buyAmount = 2 ether;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        EngineConfig.EngineParams memory _config;

        // Deploy engine, token, and load config
        (_config, stableToken, eng) = deploy.run();
        config = _config;

        // Fund test accounts
        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        STABLE TOKEN CONFIG TESTS
    //////////////////////////////////////////////////////////////*/

    function testPrecision() external view {
        assertEq(stableToken.getPrecision(), 1e10);
    }

    function testPricePrecision() external view {
        assertEq(stableToken.getPricePrecision(), 1e18);
    }

    function testBuyFee() external view {
        assertEq(stableToken.getBuyFee(), 10);
    }

    function testSellFee() external view {
        assertEq(stableToken.getSellFee(), 15);
    }

    function testFeePrecision() external view {
        assertEq(stableToken.getFeePrecision(), 100);
    }

    function testFeeAddress() external view {
        // Fee address should match price feed address from config
        assertEq(stableToken.getFeeAddress(), config.priceFeed);
    }

    /*//////////////////////////////////////////////////////////////
                        BUY TOKEN FAILURE CASES
    //////////////////////////////////////////////////////////////*/

    function testBuyTokenFailedZeroEthSent() external {
        vm.prank(user);
        vm.expectRevert(StableToken.StableToken__EthAmountCantBeZero.selector);
        stableToken.buyToken(user);
    }

    function testBuyTokenFailedOnlyOwner() external {
        // Non-owner attempting to buy should revert
        vm.prank(user2);
        vm.expectRevert();
        stableToken.buyToken{value: buyAmount}(user);
    }

    function testBuyFailedToAddressZero() external {
        vm.prank(user);
        vm.expectRevert(StableToken.StableToken__UserBuyingAddressCantBeZero.selector);
        stableToken.buyToken{value: buyAmount}(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE CONVERSION TESTS
    //////////////////////////////////////////////////////////////*/

    function testEthConverter() external {
        vm.prank(user);
        uint256 ethWorth = stableToken.getAndConvertEthPrice(buyAmount);

        // 2 ETH * $3000 = $6000 (assuming mocked feed)
        assertEq(ethWorth, 6000e18);
    }

    function testConvertUSDToEth() external {
        uint256 ethAmount = stableToken.convertUSDToEth(6000e18);
        assertEq(ethAmount, buyAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        BUY TOKEN SUCCESS
    //////////////////////////////////////////////////////////////*/

    function testBuyTokenSucceeded() external {
        vm.prank(user);
        stableToken.buyToken{value: buyAmount}(user);

        uint256 ethWorth = stableToken.getAndConvertEthPrice(buyAmount);

        // Buy fee = 10%
        uint256 fee = (ethWorth * 10) / 100;
        uint256 mintAmount = ethWorth - fee;

        assertEq(stableToken.balanceOf(user), mintAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        SELL TOKEN FAILURE CASES
    //////////////////////////////////////////////////////////////*/

    function testSellTokenCheckUserHasZeroBalance() external {
        vm.prank(user);
        vm.expectRevert(StableToken.StableToken__BalanceIsZero.selector);
        stableToken.sellToken(user1, buyAmount);
    }

    function testSellFailedCantSendToAddressZero() external {
        vm.startPrank(user);
        stableToken.buyToken{value: buyAmount}(user);

        vm.expectRevert(StableToken.StableToken__UserSellingAddressCantBeZero.selector);
        stableToken.sellToken(address(0), buyAmount);

        vm.stopPrank();
    }

    function testSellTokenFailedWithdrawMoreThanDeposit() external {
        vm.startPrank(user);
        stableToken.buyToken{value: buyAmount}(user);

        vm.expectRevert(StableToken.StableToken__InsufficientBalance.selector);
        stableToken.sellToken(user, buyAmount * 13e18);

        vm.stopPrank();
    }

    function testSellTokenRevertNoLiquidity() external {
        vm.startPrank(user);
        stableToken.buyToken{value: buyAmount}(user);

        // Owner removes liquidity before sell
        stableToken.removeLiquidity();

        vm.expectRevert(StableToken.StableToken__NoEnoughLiquidity.selector);
        stableToken.sellToken(user, buyAmount);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        SELL TOKEN SUCCESS
    //////////////////////////////////////////////////////////////*/

    function testSellTokenSucceeded() external {
        vm.startPrank(user);
        stableToken.buyToken{value: buyAmount}(user);

        uint256 userTokenBalance = stableToken.balanceOf(user);
        uint256 userEthBalanceBefore = user.balance;

        uint256 ethWorth = stableToken.convertUSDToEth(userTokenBalance);

        // Sell fee = 15%
        uint256 sellFee = (ethWorth * 15) / 100;
        uint256 ethAmount = ethWorth - sellFee;

        stableToken.sellToken(user, userTokenBalance);

        assertEq(user.balance, userEthBalanceBefore + ethAmount);
        assertEq(stableToken.balanceOf(user), 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    LOW-LEVEL CALL FAILURE TESTS
    //////////////////////////////////////////////////////////////*/

    function testSellTokenSucceededButFailedToSendEth() external {
        vm.startPrank(user);
        stableToken.buyToken{value: buyAmount}(user);

        uint256 userBalance = stableToken.balanceOf(user);

        // Engine contract cannot receive ETH -> .call fails
        vm.expectRevert(StableToken.StableToken__FailedToTransferEth.selector);
        stableToken.sellToken(address(eng), userBalance);

        vm.stopPrank();
    }

    function testSellTokenRevertFailedWithdrawEthLiquidity() external {
        vm.startPrank(user);
        stableToken.buyToken{value: buyAmount}(user);

        // Transfer ownership so engine controls liquidity
        stableToken.transferOwnership(address(eng));
        vm.stopPrank();

        vm.prank(address(eng));
        vm.expectRevert(StableToken.StableToken__FailedToWithdrawEthLiquidity.selector);
        stableToken.removeLiquidity();
    }
}
