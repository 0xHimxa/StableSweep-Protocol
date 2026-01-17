# Project Documentation - FortuneFlip Stable Token

## Overview
This project implements a decentralized stable token system called "FortuneFlip" (symbol: FLIP) built on Ethereum using Solidity and Foundry. The token allows users to buy and sell tokens pegged to ETH value through Chainlink price feeds.

## Project Structure
```
tiket/
├── src/
│   └── StableToken.sol          # Main token contract
├── foundry.toml                  # Foundry configuration
├── foundry.lock                  # Dependency lock file
├── lib/                          # External dependencies
│   ├── openzeppelin-contracts/   # OpenZeppelin ERC20 implementation
│   └── chainlink-brownie-contracts/ # Chainlink price feeds
├── out/                          # Compiled contract artifacts
├── cache/                        # Build cache
└── noteSelf.md                   # Development notes
```

## What Has Been Done So Far

### 1. Development Environment Setup ✅
- Initialized Foundry project
- Configured `foundry.toml` with proper remappings
- Installed OpenZeppelin contracts for ERC20 implementation
- Installed Chainlink contracts for price feed integration

### 2. Core Token Implementation ✅
- **Contract**: `StableToken.sol` (146 lines)
- **Inheritance**: Extends OpenZeppelin's ERC20
- **Token Name**: "FortuneFlip"
- **Token Symbol**: "FLIP"
- **License**: MIT

### 3. Key Features Implemented

#### Buy Functionality ✅
- `buyToken(address to)` - Allows users to purchase tokens with ETH
- Uses Chainlink ETH/USD price feed (Sepolia testnet: `0x694AA1769357215DE4FAC081bf1f309aDC325306`)
- Converts ETH sent to equivalent token amount
- Mints tokens directly to recipient address

#### Sell Functionality ✅
- `sellToken(address to, uint256 amount)` - Allows users to sell tokens back for ETH
- Burns tokens from caller
- Calculates ETH equivalent based on current price
- Transfers ETH to recipient address
- Includes liquidity checks

#### Security Measures ✅
- Custom error definitions for gas efficiency
- Input validation modifiers:
  - `ethAmountAndAddressChecks()` - Validates ETH amount and recipient address
  - `checkBalanceOfUser(uint256 _amount)` - Ensures sufficient token balance
- Protection against zero addresses and zero amounts
- Liquidity validation for sell operations

### 4. Price Integration ✅
- Chainlink AggregatorV3Interface integration
- Real-time ETH/USD price fetching
- Precision handling for price calculations
- Constants for scaling (`PRECISION = 1e10`, `PRICE_PRECISION = 1e18`)

### 5. Git History
Recent commits show progressive development:
1. `00ef9bd` - Completed sell token logic refactor
2. `4849436` - Implemented buy functionality  
3. `8578870` - Created protocol token and implemented buy token
4. `d0a47b2` - Removed default README
5. `b885fff` - Installed needed dependencies
6. `f851ca5` - Set up development environment

## Current Issues & Notes

### Known Issues (from noteSelf.md)
- **Withdrawal Logic Issue**: There's a problem with the sell token logic where users are paid based on price drops - needs investigation
- **Pegging**: Token is not yet tightly pegged to ETH as intended
- **Complexity**: Developer wants to make the system more complex before fixing the withdrawal issue

### Technical Debt
- Price feed address is hardcoded (Sepolia testnet)
- No admin functions for contract management
- No emergency pause mechanisms
- Limited error handling for edge cases

## Next Steps (Based on noteSelf.md)
1. Fix the withdrawal logic issue related to price drop payments
2. Implement proper ETH pegging mechanism
3. Add complexity to the system as planned
4. Consider adding admin functions and security features

## Dependencies
- **OpenZeppelin Contracts**: For ERC20 token standard implementation
- **Chainlink Contracts**: For price feed integration
- **Foundry**: For development, testing, and deployment

## Deployment Information
- **Network**: Currently configured for Sepolia testnet
- **Price Feed**: ETH/USD AggregatorV3Interface
- **Compiler**: Solidity ^0.8.19

---
*Documentation generated on January 17, 2026*