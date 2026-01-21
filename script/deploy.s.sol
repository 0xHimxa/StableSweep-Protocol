// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {EngineConfig} from "./config.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployEngine is Script {
    uint256 subId;

    LinkTokenInterface LINKTOKEN;

    function run() public {
        EngineConfig config = new EngineConfig();
        EngineConfig.EngineParams memory params = config.getNetworkConfig();

        vm.startBroadcast();
        if (params.subId == 0) {
            console.log(params.subId, "here");

            params.subId = VRFCoordinatorV2_5Mock(params.vrfCoordnator).createSubscription();
        }

        StableToken stableToken = new StableToken();
        RaffileEngine engine = new RaffileEngine(
            address(stableToken), params.vrfCoordnator, params.keyHash, params.linkToken, params.subId
        );

        stableToken.transferOwnership(address(engine));

        VRFCoordinatorV2_5Mock(params.vrfCoordnator).addConsumer(params.subId, address(engine));

        vm.stopBroadcast();
    }
}

