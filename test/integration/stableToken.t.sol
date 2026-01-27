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
    address engAddress;

    // Test users
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user1 = makeAddr("user12");
    address user2 = makeAddr("user23");

    // Common test amount
    uint256 buyAmount = 2 ether;
    CallFailed callFail;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        EngineConfig.EngineParams memory _config;

        // Deploy engine, token, and load config
        (_config, stableToken, eng) = deploy.run();
        config = _config;
        engAddress = address(eng);
        callFail = new CallFailed();

        // Fund test accounts
        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(engAddress, 100 ether);
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
        vm.prank(engAddress);
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
        vm.prank(engAddress);
        vm.expectRevert(
            StableToken.StableToken__UserBuyingAddressCantBeZero.selector
        );
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
        // Test Scenario:
        // 1. Engine contract (owner) buys tokens.
        // 2. Value sent: 2 ETH ($6000 assumed).
        // 3. Buy Fee: 10%.
        // 4. Expected: User gets $5400 worth of tokens.

        vm.prank(engAddress);
        stableToken.buyToken{value: buyAmount}(user);

        uint256 ethWorth = stableToken.getAndConvertEthPrice(buyAmount);

        // Fee Math:
        // Fee = (6000 * 10) / 100 = 600
        // Mint = 6000 - 600 = 5400
        uint256 fee = (ethWorth * 10) / 100;
        uint256 mintAmount = ethWorth - fee;

        assertEq(stableToken.balanceOf(user), mintAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        SELL TOKEN FAILURE CASES
    //////////////////////////////////////////////////////////////*/

    function testSellTokenCheckUserHasZeroBalance() external {
        // Scenario: User tries to sell tokens they don't have.
        // Expected: Revert with BalanceIsZero.
        vm.prank(engAddress);
        vm.expectRevert(StableToken.StableToken__BalanceIsZero.selector);
        stableToken.sellToken(user1, buyAmount);
    }

    function testSellFailedCantSendToAddressZero() external {
        vm.startPrank(address(eng));
        stableToken.buyToken{value: buyAmount}(engAddress);

        // Scenario: User tries to withdraw ETH to address(0).
        // Expected: Revert with UserSellingAddressCantBeZero.
        vm.expectRevert(
            StableToken.StableToken__UserSellingAddressCantBeZero.selector
        );
        stableToken.sellToken(address(0), buyAmount);

        vm.stopPrank();
    }

    function testSellTokenFailedWithdrawMoreThanDeposit() external {
        vm.startPrank(engAddress);
        stableToken.buyToken{value: buyAmount}(engAddress);

        // Scenario: User tries to sell more tokens than their balance.
        // Expected: Revert with InsufficientBalance.
        vm.expectRevert(StableToken.StableToken__InsufficientBalance.selector);
        stableToken.sellToken(engAddress, buyAmount * 13e18);

        vm.stopPrank();
    }

    function testSellTokenRevertNoLiquidity() external {
        vm.startPrank(engAddress);
        stableToken.buyToken{value: buyAmount}(engAddress);

        // Scenario: Liquidity allows selling, but contract has been drained.
        // Action: Owner calls removeLiquidity().
        // Expected: Revert with NoEnoughLiquidity.
        stableToken.removeLiquidity();

        vm.expectRevert(StableToken.StableToken__NoEnoughLiquidity.selector);
        stableToken.sellToken(engAddress, buyAmount);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        SELL TOKEN SUCCESS
    //////////////////////////////////////////////////////////////*/

    function testSellTokenSucceeded() external {
        // Test Scenario:
        // 1. User has tokens from a previous buy.
        // 2. User sells all tokens.
        // 3. Sell Fee: 15%.
        // 4. Expected: User receives 85% of the ETH value.

        vm.startPrank(engAddress);
        stableToken.buyToken{value: buyAmount}(engAddress);

        uint256 userTokenBalance = stableToken.balanceOf(engAddress);
        uint256 userEthBalanceBefore = engAddress.balance;

        uint256 ethWorth = stableToken.convertUSDToEth(userTokenBalance);

        // Fee Math:
        // Sell Fee = (ETH Value * 15) / 100
        // Payout = ETH Value - Sell Fee
        uint256 sellFee = (ethWorth * 15) / 100;
        uint256 ethAmount = ethWorth - sellFee;

        stableToken.sellToken(engAddress, userTokenBalance);

        assertEq(engAddress.balance, userEthBalanceBefore + ethAmount);
        assertEq(stableToken.balanceOf(engAddress), 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    LOW-LEVEL CALL FAILURE TESTS
    //////////////////////////////////////////////////////////////*/

    function testSellTokenSucceededButFailedToSendEth() external {
        // Scenario: Contract tries to send ETH to a contract that cannot receive it.
        // Target: CallFailed contract (no receive/fallback function).
        // Expected: Revert with FailedToTransferEth.

        vm.startPrank(engAddress);
        stableToken.buyToken{value: buyAmount}(engAddress);

        uint256 userBalance = stableToken.balanceOf(engAddress);

        vm.expectRevert(StableToken.StableToken__FailedToTransferEth.selector);
        stableToken.sellToken(address(callFail), userBalance);

        vm.stopPrank();
    }

    function testSellTokenRevertFailedWithdrawEthLiquidity() external {
        vm.startPrank(engAddress);
        stableToken.buyToken{value: buyAmount}(engAddress);

        // Scenario: Owner tries to remove liquidity to a contract that rejects ETH.
        // Expected: Revert with FailedToWithdrawEthLiquidity.
        stableToken.transferOwnership(address(callFail));
        vm.stopPrank();

        vm.prank(address(callFail));
        vm.expectRevert(
            StableToken.StableToken__FailedToWithdrawEthLiquidity.selector
        );
        stableToken.removeLiquidity();
    }
}

contract CallFailed {}
