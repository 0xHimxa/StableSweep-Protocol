// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";

contract TestStabeleToken is Test {
    StableToken stableToken;

    EngineConfig.EngineParams config;
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user2 = makeAddr("user23");

    uint256 buyAmount = 2 ether;

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        EngineConfig.EngineParams memory _config;
        (_config, stableToken,) = deploy.run();

        config = _config;

        vm.deal(user, 100 ether);
        vm.deal(user2, 100 ether);
    }
}
