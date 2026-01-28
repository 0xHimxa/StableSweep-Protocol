# Quick Start Guide

## Local Development Setup

1. **Install Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Clone and Build**
   ```bash
   git clone <repo-url>
   cd tiket
   forge install
   forge build
   ```

3. **Run Tests**
   ```bash
   forge test
   forge test --gas-report
   forge coverage --report lcov
   ```

4. **Local Deployment**
   ```bash
   anvil
   forge script script/deployment/deploy.s.sol --rpc-url http://localhost:8545 --broadcast
   ```

## Key Commands

```bash
# Build
forge build

# Test
forge test
forge test -vvv  # Verbose output
forge test --match-test testFunctionName

# Deploy
forge script script/deployment/deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Verify
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain-id <CHAIN_ID>

# Coverage
forge coverage
forge coverage --report lcov
```

## Test Structure

- `test/unit/` - Individual contract function tests
- `test/integration/` - Contract interaction tests  
- `test/fuzz/` - Property-based tests
- `test/invariant/` - System-wide invariant tests

## Deployment Structure

- `script/deployment/` - Contract deployment scripts
- `script/utils/` - Helper utilities and configurations