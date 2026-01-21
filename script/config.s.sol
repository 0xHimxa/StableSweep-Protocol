//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";

contract EngineConfig is Script {
    error EngineConfig__NetworkNotSupport();

    uint256 public constant anvilChainId = 31337;
    uint256 public constant sepoliaChainId = 11155111;
    uint256 public constant goerliChainId = 5;
    uint256 public constant mainnetChainId = 1;
    uint96 constant baseFee = 0.25 ether; // 0.25 LINK
    uint96 constant gasPrice = 1e9; // 1 gwei
    int256 constant weiPerUnitLink = 1e18;

    struct EngineParams {
        address vrfCoordnator;
        bytes32 keyHash;
        address linkToken;
        uint256 subId;
    }
    EngineParams localConfig;

    function getNetworkConfig() public returns (EngineParams memory) {
        if (block.chainid == anvilChainId) {
            return getAvilConfig();
        } else if (block.chainid == sepoliaChainId) {
            return getSepoliaConfig();
        } else {
            revert EngineConfig__NetworkNotSupport();
        }
    }

    function getSepoliaConfig() public pure returns (EngineParams memory) {
        return EngineParams({
            vrfCoordnator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            subId: 0
        });
    }

    function getAvilConfig() public returns (EngineParams memory) {
        if (localConfig.vrfCoordnator != address(0)) {
            return localConfig;
        }

        vm.startBroadcast();

        VRFCoordinatorV2_5Mock vrf = new VRFCoordinatorV2_5Mock(baseFee, gasPrice, weiPerUnitLink);
        MockLinkToken link = new MockLinkToken();

        vm.stopBroadcast();

        localConfig =
            EngineParams({vrfCoordnator: address(vrf), keyHash: bytes32(0), linkToken: address(link), subId: 0});

        return localConfig;
    }
}

