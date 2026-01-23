// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {EngineConfig} from "./config.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployEngine is Script {
    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    uint256 subId;

    // LINK token interface (used for funding VRF subscriptions on live networks)
    LinkTokenInterface LINKTOKEN;

    // Default Anvil/Foundry deployer address
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // Amount of LINK to fund the VRF subscription
    uint256 linkFunding = 3 ether;

    /*//////////////////////////////////////////////////////////////
                                RUN
    //////////////////////////////////////////////////////////////*/

    function run()
        public
        returns (EngineConfig.EngineParams memory params, StableToken stableToken, RaffileEngine engine)
    {
        // Load network-specific configuration
        EngineConfig config = new EngineConfig();
        params = config.getNetworkConfig();

        // Begin broadcasting transactions from the deployer address
        vm.startBroadcast(user);

        /*//////////////////////////////////////////////////////////////
                        VRF SUBSCRIPTION SETUP
        //////////////////////////////////////////////////////////////*/

        // If no subscription exists, create a new one
        if (params.subId == 0) {
            console.log(params.subId, "existing subId");

            // Prevent underflow in local chain simulations
            vm.roll(1);

            // Create a new VRF subscription
            params.subId = VRFCoordinatorV2_5Mock(params.vrfCoordinator).createSubscription();

            console.log(params.subId, "new subscription created");
        }

        /*//////////////////////////////////////////////////////////////
                        CONTRACT DEPLOYMENT
        //////////////////////////////////////////////////////////////*/

        // Deploy the StableToken contract
        stableToken = new StableToken(params.priceFeed);

        // Deploy the RaffleEngine with required dependencies
        engine = new RaffileEngine(
            address(stableToken), params.vrfCoordinator, params.keyHash, params.linkToken, params.subId
        );

        // Transfer StableToken ownership to the engine

        //  stableToken.transferOwnership(address(engine));

        // Register the engine as a consumer of the VRF subscription
        VRFCoordinatorV2_5Mock(params.vrfCoordinator).addConsumer(params.subId, address(engine));

        /*//////////////////////////////////////////////////////////////
                        VRF FUNDING LOGIC
        //////////////////////////////////////////////////////////////*/

        if (block.chainid == 31337) {
            // Local Anvil chain: fund subscription directly via mock
            VRFCoordinatorV2_5Mock(params.vrfCoordinator).fundSubscription(params.subId, linkFunding);
        } else if (block.chainid == 11155111) {
            // Sepolia: fund subscription via LINK token transferAndCall
            LinkTokenInterface(params.linkToken)
                .transferAndCall(params.vrfCoordinator, linkFunding, abi.encode(params.subId));
        }

        // Stop broadcasting transactions
        vm.stopBroadcast();

        return (params, stableToken, engine);
    }
}
