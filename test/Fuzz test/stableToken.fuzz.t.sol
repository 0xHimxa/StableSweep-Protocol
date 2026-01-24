// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {RaffileEngine} from "src/engine.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

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

        // Fund test accounts
        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(engAddress, 100 ether);
    }

    function testBuyToken(uint88 amount, address to) external {
        vm.assume(to != address(0));
        uint256 amountUse = bound(amount, 1, type(uint88).max);
        vm.deal(to, amountUse);
        vm.prank(engAddress);
        stableToken.transferOwnership(to);

        vm.prank(to);
        stableToken.buyToken{value: amountUse}(to);

        uint256 amountUsedWorth = stableToken.getAndConvertEthPrice(amountUse);
        uint256 fee = (amountUsedWorth * stableToken.getBuyFee()) / stableToken.getFeePrecision();

        uint256 mintingAmount = amountUsedWorth - fee;

        assertEq(stableToken.balanceOf(to), mintingAmount);
        assertEq(address(stableToken).balance, amountUse);
    }

    function testBuyTokenOnlyOwner(uint88 amount, address to) external {
       vm.assume(to.code.length == 0);
       
       
        uint256 amountUse = bound(amount, 1, type(uint88).max);
        vm.deal(to, amountUse);

        vm.prank(to);
        vm.expectRevert();
        stableToken.buyToken{value: amountUse}(to);
    }

    function testSellToken(uint88 amount, address to) external {
        vm.assume(to.code.length == 0);
        vm.assume(to != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        vm.assume(to != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(uint160(to) > 100);

        uint256 amountUse = bound(amount, 1, type(uint88).max);
        vm.deal(to, amountUse);
        vm.prank(engAddress);
        stableToken.transferOwnership(to);

        vm.startPrank(to);
        stableToken.buyToken{value: amountUse}(to);
        uint256 stableBalance = address(stableToken).balance;

        console.log(stableBalance, "token eth ball first");

        uint256 userEthBalance = to.balance;
        uint256 userTokenBalance = stableToken.balanceOf(to);

        stableToken.sellToken(to, userTokenBalance);

        vm.stopPrank();
        console.log(address(stableToken).balance, "token eth ball second", stableBalance);
        uint256 tokenToEth = stableToken.convertUSDToEth(userTokenBalance);
        uint256 fee = (tokenToEth * stableToken.getSellFee()) / stableToken.getFeePrecision();
        uint256 ethSend = tokenToEth - fee;

        assertEq(to.balance, userEthBalance + ethSend);
        assertEq(address(stableToken).balance, stableBalance - ethSend);
        assertEq(stableToken.balanceOf(to), 0);
    }

    function testSellTokenRevertOnlyOwner(uint88 amount, address to) external {
        vm.assume(to.code.length == 0);
        vm.assume(to != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        vm.assume(to != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(uint160(to) > 100);

        uint256 amountUse = bound(amount, 1, type(uint88).max);
        vm.deal(to, amountUse);
        vm.prank(engAddress);
        stableToken.transferOwnership(to);

        vm.startPrank(to);
        stableToken.buyToken{value: amountUse}(to);
        stableToken.transferOwnership(engAddress);
        vm.stopPrank();

        vm.prank(to);
        vm.expectRevert();
        stableToken.sellToken(to, amountUse);
    }



    function testRomveLiquidityRevert(address to) external {

vm.prank(to);
vm.expectRevert();
stableToken.removeLiquidity();

    }
}
