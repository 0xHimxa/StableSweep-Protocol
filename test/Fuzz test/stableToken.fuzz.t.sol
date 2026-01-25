// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {RaffileEngine} from "src/engine.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestStableToken is Test {
    StableToken stableToken;
    RaffileEngine eng;
    EngineConfig.EngineParams config;

    address owner;
    address user;

    uint256 constant MAX_ETH = 1_000 ether;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        (config, stableToken, eng) = deploy.run();

        owner = address(eng);
        user = makeAddr("user");

        vm.deal(user, MAX_ETH);
        vm.deal(owner, MAX_ETH);
    }

    /*//////////////////////////////////////////////////////////////
                        BUY TOKEN (OWNER ONLY)
    //////////////////////////////////////////////////////////////*/

    function testFuzz_buyToken(uint256 ethAmount) external {
        ethAmount = bound(ethAmount, 1 ether, MAX_ETH);

        vm.startPrank(owner);
        stableToken.transferOwnership(user);
        vm.stopPrank();

        uint256 ethBefore = address(stableToken).balance;

        vm.prank(user);
        stableToken.buyToken{value: ethAmount}(user);

        uint256 worth = stableToken.getAndConvertEthPrice(ethAmount);
        uint256 fee = (worth * stableToken.getBuyFee()) / stableToken.getFeePrecision();
        uint256 mintAmount = worth - fee;

        assertEq(stableToken.balanceOf(user), mintAmount);
        assertEq(address(stableToken).balance, ethBefore + ethAmount);
    }

    function testBuyTokenRevertNotOwner(uint256 ethAmount) external {
        ethAmount = bound(ethAmount, 1 ether, MAX_ETH);
        vm.deal(user, ethAmount);

        vm.prank(user);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));

        stableToken.buyToken{value: ethAmount}(user);
    }

    /*//////////////////////////////////////////////////////////////
                        SELL TOKEN (OWNER ONLY)
    //////////////////////////////////////////////////////////////*/

    function testFuzz_sellToken(uint256 ethAmount) external {
        ethAmount = bound(ethAmount, 1 ether, MAX_ETH);

        vm.startPrank(owner);
        stableToken.transferOwnership(user);
        vm.stopPrank();

        vm.startPrank(user);
        stableToken.buyToken{value: ethAmount}(user);

        uint256 tokenBal = stableToken.balanceOf(user);
        uint256 ethBefore = user.balance;
        uint256 tokenEthBefore = address(stableToken).balance;

        stableToken.sellToken(user, tokenBal);
        vm.stopPrank();

        uint256 ethValue = stableToken.convertUSDToEth(tokenBal);
        uint256 fee = (ethValue * stableToken.getSellFee()) / stableToken.getFeePrecision();
        uint256 ethOut = ethValue - fee;

        assertEq(user.balance, ethBefore + ethOut);
        assertEq(address(stableToken).balance, tokenEthBefore - ethOut);
        assertEq(stableToken.balanceOf(user), 0);
    }

    function testSellTokenRevertNotOwner(uint256 ethAmount) external {
        ethAmount = bound(ethAmount, 1 ether, MAX_ETH);

        vm.startPrank(owner);
        stableToken.transferOwnership(user);
        vm.stopPrank();

        vm.prank(user);
        stableToken.buyToken{value: ethAmount}(owner);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        stableToken.sellToken(user, ethAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        REMOVE LIQUIDITY
    //////////////////////////////////////////////////////////////*/

    //Only Owner can remove it

    function testRemoveLiquidityRevertNotOwner() external {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));

        stableToken.removeLiquidity();
    }
}
