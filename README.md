# FortuneFlip Stable Token

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Foundry](https://img.shields.io/badge/built%20with-Foundry-orange)
![Status](https://img.shields.io/badge/status-Development-yellow)

FortuneFlip (FLIP) is a decentralized stable token system built on Ethereum, featuring a rigorous fee structure and a fully integrated on-chain raffle engine powered by Chainlink VRF.

## Overview

The FortuneFlip ecosystem consists of two core smart contracts designed to work in tandem:

1.  **StableToken**: An ERC20 token pegged to ETH value via Chainlink Price Feeds. It implements a sustainable economic model with a 10% buy fee and a 15% sell fee.
2.  **RaffleEngine**: A decentralized raffle platform where users can convert FLIP tokens into tickets, enter rounds, and win the pooled tokens. Winner selection is verifiable and automated using Chainlink VRF V2.5.

## Architecture

The project follows a modular architecture:

-   **Src**: Core smart contracts.
-   **Script**: Deployment and configuration scripts supporting multi-network setups (Anvil, Sepolia).
-   **Test**: Comprehensive test suite including unit, integration, and fuzz tests.

## Key Features

-   **Algorithmic Stability**: Token value is derived from ETH/USD Chainlink feeds.
-   **Fee Mechanics**: 100 basis point precision for accurate fee calculation.
-   **Verifiable Randomness**: Chainlink VRF integration regarding winner selection guarantees fairness.
-   **Automated Maintenance**: Chainlink Automation ready for round management.

## Getting Started

### Prerequisites

-   [Foundry](https://getfoundry.sh/)
-   [Make](https://www.gnu.org/software/make/) (optional, if using Makefile)

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/ticket.git
    cd ticket
    ```

2.  Install dependencies:
    ```bash
    forge install
    ```

### Testing

Run the full test suite:
```bash
forge test
```

Run integration tests:
```bash
forge test --match-path test/integration/*
```

## Deployment

### Local Development (Anvil)

1.  Start local node:
    ```bash
    anvil
    ```

2.  Deploy contracts:
    ```bash
    forge script script/deploy.s.sol --rpc-url http://localhost:8545 --broadcast
    ```

### Testnet (Sepolia)

1.  Set up environment variables:
    ```bash
    export SEPOLIA_RPC_URL="<your_rpc_url>"
    export PRIVATE_KEY="<your_private_key>"
    export ETHERSCAN_API_KEY="<your_api_key>"
    ```

2.  Deploy:
    ```bash
    forge script script/deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
    ```

## Documentation

For detailed technical documentation, please refer to the `docs/` directory:

-   [Architecture & Design](docs/ARCHITECTURE.md)
-   [Development Guide](docs/DEVELOPMENT.md)

## Security

This project is currently in **development** and has not been audited. Use at your own risk.

## License

This project is licensed under the MIT License.
