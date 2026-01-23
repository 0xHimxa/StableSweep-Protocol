// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";

contract TestStabeleToken is Test {

    event UserBuyToken(address indexed user, uint256 amount);



    StableToken stableToken;

    EngineConfig.EngineParams config;
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user2 = makeAddr("user23");
RaffileEngine engine;
    uint256 buyAmount = 2 ether;

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        EngineConfig.EngineParams memory _config;
        (_config, stableToken,engine) = deploy.run();

        config = _config;

        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
    }

function testStableTokenAddress() external view{

assertEq(address(stableToken), address(engine.stableToken()));


}

function testRafileIdIsZero() external view{

assertEq(engine.raffleId(), 0);

}

function testEntranceFee() external view{

assertEq(engine.entranceFee(), 5e18);

}

function testMaxTicketsPerRound() external view{

assertEq(engine.maxTicketsPerRound(), 10);

}   

function  testTotalLockedTokens() external view{

assertEq(engine.totalLockedTokens(), 0);

}

function testKeyHash() external view{

assertEq(engine.getKeyHash(), config.keyHash);

}


function testLinkToken() external view{

assertEq(engine.getLinkToken(), config.linkToken);

}

function testSubscriptionId() external view{

assertEq(engine.getSubscriptionId(), config.subId);

}


// testing  Buy Token 

function testRaffileBuyTokenFailedZeroEthSent() external {
vm.prank(user2);
 vm.expectRevert(RaffileEngine.RaffileEngine__EthAmountCantBeZero.selector);
engine.buyRaffileToken();



}


function testRafileBuyTokenSucced()external{

vm.startPrank(user);
//stableToken.transferOwnership(address(engine));



vm.expectEmit(true, false, false, true);
emit UserBuyToken(user, buyAmount);
engine.buyRaffileToken{value: buyAmount}();
vm.stopPrank();

}




}
