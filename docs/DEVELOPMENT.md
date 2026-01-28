# Development Guide

This guide covers the setup, testing, and deployment workflow for the FortuneFlip project.

## Environment Setup

1.  **Install Foundry**:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

2.  **Environment Variables**:
    Create a `.env` file in the root directory:
    ```ini
    SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
    PRIVATE_KEY=0x...
    ETHERSCAN_API_KEY=...
    COINMARKETCAP_API_KEY=...
    ```

## Project Structure

-   `src/`: Smart contracts (`StableToken.sol`, `engine.sol`).
-   `script/`: Deployment (`DeployEngine.s.sol`) and configuration (`EngineConfig.s.sol`) scripts.
-   `test/`:
    -   `unit/`: Unit tests for individual functions.
    -   `integration/`: End-to-end flow tests.
    -   `invariant/`: Invariant/fuzz tests.

## Testing

### Running Tests
Execute all tests:
```bash
forge test
```

### Coverage
Generate a coverage report:
```bash
forge coverage
```

### Verbose Logging
Debug specific tests with trace:
```bash
forge test --mt <test_function_name> -vvvv
```

## Deployment

The project uses a modular deployment script located in `script/deploy.s.sol`.

### Deployment to Anvil (Localhost)
1.  Start Anvil:
    ```bash
    anvil
    ```
2.  Deploy:
    ```bash
    forge script script/deploy.s.sol --rpc-url http://localhost:8545 --broadcast
    ```

### Deployment to Sepolia
1.  Ensure your wallet is funded with Sepolia ETH.
2.  Run the deployment script:
    ```bash
    forge script script/deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --account <account_name> --broadcast --verify
    ```

## Code Verification
After deployment, contracts can be verified on Etherscan automatically if the `--verify` flag is used with an Etherscan API key.

To manually verify:
```bash
forge verify-contract <address> <contract_path>:<contract_name> --chain-id <chain_id> --watch
```
