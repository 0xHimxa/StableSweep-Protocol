//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {MockV3Aggregator} from "test/priceMock.sol";

/*//////////////////////////////////////////////////////////////
                        ENGINE CONFIG
//////////////////////////////////////////////////////////////*/

contract EngineConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error EngineConfig__NetworkNotSupported();

    /*//////////////////////////////////////////////////////////////
                        CHAIN IDENTIFIERS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant ANVIL_CHAIN_ID   = 31337;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant GOERLI_CHAIN_ID  = 5;
    uint256 public constant MAINNET_CHAIN_ID = 1;

    /*//////////////////////////////////////////////////////////////
                    CHAINLINK MOCK PARAMETERS
    //////////////////////////////////////////////////////////////*/

    // VRF mock configuration
    uint96 internal constant BASE_FEE = 0.25 ether; // 0.25 LINK
    uint96 internal constant GAS_PRICE = 1e9;        // 1 gwei
    int256 internal constant WEI_PER_LINK = 4e15;    // LINK/ETH rate

    // Price feed mock configuration
    uint8 internal constant PRICE_FEED_DECIMALS = 8;
    int256 internal constant INITIAL_PRICE = 3000e8; // $3000 with 8 decimals

    /*//////////////////////////////////////////////////////////////
                        SCRIPT CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    // Default Anvil broadcaster (Foundry first account)
    address internal constant DEFAULT_ANVIL_USER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /*//////////////////////////////////////////////////////////////
                            DATA TYPES
    //////////////////////////////////////////////////////////////*/

    struct EngineParams {
        address vrfCoordinator;
        bytes32 keyHash;
        address linkToken;
        uint256 subId;
        address priceFeed;
    }

    /*//////////////////////////////////////////////////////////////
                        STORAGE
    //////////////////////////////////////////////////////////////*/

    // Cached local (Anvil) configuration to avoid redeploying mocks
    EngineParams internal localConfig;

    /*//////////////////////////////////////////////////////////////
                        PUBLIC API
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the correct configuration based on the active chain
     */
    function getNetworkConfig() public returns (EngineParams memory) {
        if (block.chainid == ANVIL_CHAIN_ID) {
            return getAnvilConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            return getSepoliaConfig();
        } else {
            revert EngineConfig__NetworkNotSupported();
        }
    }

    /**
     * @notice Sepolia configuration using live Chainlink contracts
     * @dev No state changes, so function is pure
     */
    function getSepoliaConfig()
        public
        pure
        returns (EngineParams memory)
    {
        return EngineParams({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            subId: 0,
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    /**
     * @notice Local Anvil configuration
     * @dev Deploys mocks only once and caches the result
     */
    function getAnvilConfig()
        public
        returns (EngineParams memory)
    {
        // Return cached config if mocks already exist
        if (localConfig.vrfCoordinator != address(0)) {
            return localConfig;
        }

        vm.startBroadcast(DEFAULT_ANVIL_USER);

        // Deploy Chainlink mocks
        VRFCoordinatorV2_5Mock vrfCoordinator =
            new VRFCoordinatorV2_5Mock(
                BASE_FEE,
                GAS_PRICE,
                WEI_PER_LINK
            );

        MockLinkToken linkToken = new MockLinkToken();

        MockV3Aggregator priceFeed =
            new MockV3Aggregator(
                PRICE_FEED_DECIMALS,
                INITIAL_PRICE
            );

        vm.stopBroadcast();

        // Cache deployed addresses
        localConfig = EngineParams({
            vrfCoordinator: address(vrfCoordinator),
            keyHash: bytes32(0),
            linkToken: address(linkToken),
            subId: 0,
            priceFeed: address(priceFeed)
        });

        return localConfig;
    }
}