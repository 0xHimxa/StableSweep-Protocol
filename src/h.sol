//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Create a new subscription when the contract is initially deployed.

contract resuse {
    // Sepolia coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf/v2-5/subscription-supported-networks#configurations
    address public vrfCoordinatorV2Plus = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2-5/subscription-supported-networks#configurations
    bytes32 public keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    // Sepolia LINK token contract. For other networks, see
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address public link_token_contract = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    //Create a new subscription when you deploy the contract.
    // _createNewSubscription();

    //will need to put this in the deploy script
    // function _createNewSubscription() private //**onlyOwner**/ {
    // s_subscriptionId = s_vrfCoordinator.createSubscription();
    //Add this contract as a consumer of its own subscription.
    // s_vrfCoordinator.addConsumer(s_subscriptionId, address(this));
    //}

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    //   function topUpSubscription(
    //     uint256 amount
    //   ) external {
    //     LINKTOKEN.transferAndCall(address(s_vrfCoordinator), amount, abi.encode(s_subscriptionId));
    //   }
}
