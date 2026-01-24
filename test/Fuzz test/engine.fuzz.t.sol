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
    RaffileEngine engine;

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
        (_config, stableToken, engine) = deploy.run();
        config = _config;
        engAddress = address(engine);

        // Fund test accounts
        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(engAddress, 100 ether);
    }



function testBuyRaffileToken(uint88 amount, address to) external {

vm.assume(to != address(0));
vm.assume(to.code.length == 0);
vm.assume(uint160(to) > 10);
uint256 fundEth = bound(amount,1,type(uint88).max);
vm.deal(to, fundEth);
uint256 userBalanceB4 = to.balance;


console.log(userBalanceB4, "user Balance before buy");
vm.startPrank(to);
engine.buyRaffileToken{value: fundEth}();
vm.stopPrank();

uint256 userBalanceAfter = to.balance;
console.log(userBalanceAfter, "user Balance after buy");

assertEq(address(stableToken).balance, fundEth);
assert(userBalanceAfter == 0);



}



function testSellRaffileToken(uint88 amount, address to) external {

vm.assume(to.code.length == 0);
        vm.assume(to != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        vm.assume(to != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(uint160(to) > 100);


uint256 fundEth = bound(amount,1,type(uint88).max);
vm.deal(to, fundEth);


vm.startPrank(to);
engine.buyRaffileToken{value: fundEth}();
uint256 userBalanceB4 = to.balance;

uint256 stableBalanceB4 = address(stableToken).balance;

stableToken.approve(address(engine), fundEth);
engine.sellRaffileToken(fundEth);
vm.stopPrank();

uint256 userBalanceAfter = to.balance;
console.log(userBalanceAfter, "user Balance after buy");
uint256 stableBalance = address(stableToken).balance;


 uint256 tokenToEth = stableToken.convertUSDToEth(fundEth);
        uint256 fee = (tokenToEth * stableToken.getSellFee()) / stableToken.getFeePrecision();
        uint256 ethSend = tokenToEth - fee;


assertEq( stableBalance, stableBalanceB4 - ethSend);
assertEq(userBalanceAfter, userBalanceB4 + ethSend);



}





function testSellRaffileTokenRevert(uint88 amount, address to) external {

vm.assume(to.code.length == 0);
        vm.assume(to != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        vm.assume(to != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(uint160(to) > 100);


uint256 fundEth = bound(amount,1,type(uint88).max);
vm.deal(to, fundEth);


vm.startPrank(to);
engine.buyRaffileToken{value: fundEth}();


stableToken.approve(address(engine), fundEth);
vm.expectRevert(RaffileEngine.RaffileEngine__InsufficientBalance.selector);
engine.sellRaffileToken(fundEth * 20e18);
vm.stopPrank();



}




function testBuyRaffileTicket(uint168 amount, address to) external {

uint256 entranceFee =  5e18;

vm.assume(to.code.length == 0);
        vm.assume(to != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        vm.assume(to != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(uint160(to) > 100);


uint256 fundAmount = bound(amount,entranceFee,type(uint88).max);
vm.deal(to, fundAmount);


vm.startPrank(to);
engine.buyRaffileToken{value: fundAmount}();
uint256 userTokenBalanceB4 = stableToken.balanceOf(to);
stableToken.approve(address(engine), fundAmount);

engine.buyTickets(fundAmount);
uint256 userTokenBalaneAfter = stableToken.balanceOf(to);


vm.stopPrank();
uint256 tickets = fundAmount / entranceFee;
      uint256 cost = tickets * entranceFee;



assertEq(userTokenBalaneAfter, userTokenBalanceB4 - cost);
 assertEq(address(stableToken).balance, fundAmount);
  assertEq(stableToken.balanceOf(address(engine)), cost);
  assertEq(engine.ticketBalance(to), tickets);
  console.log(tickets,"user Ticket balance");


}



function testBuyTicketRevert(uint168 amount, address to) external {


uint256 entranceFee =  5e18;

vm.assume(to.code.length == 0);
        vm.assume(to != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        vm.assume(to != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(uint160(to) > 100);


uint256 fundAmount = bound(amount,entranceFee,type(uint88).max);
vm.deal(to, fundAmount);


vm.startPrank(to);
engine.buyRaffileToken{value: fundAmount}();
uint256 userTokenBalanceB4 = stableToken.balanceOf(to);
stableToken.approve(address(engine), fundAmount);

vm.expectRevert(RaffileEngine.RaffileEngine__InsufficientBalanceBuyMoreToken.selector);
engine.buyTickets(fundAmount * 20e18);

vm.stopPrank();





}










}