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

### 2. Fee System Implementation ✅ (NEW - January 2026)
- **Buy Fee**: 10% fee on all token purchases
- **Sell Fee**: 15% fee on all token sales
- **Fee Precision**: 100 basis points for accurate calculations
- **Automatic Deduction**: Fees automatically deducted during transactions
- **Enhanced Logic**: Improved token minting and burning with fee considerations

### 3. Core Token Implementation ✅
- **Contract**: `StableToken.sol` (148 lines)
- **Inheritance**: Extends OpenZeppelin's ERC20 and Ownable
- **Token Name**: "FortuneFlip"
- **Token Symbol**: "FLIP"
- **License**: MIT
- **NEW**: Fee system constants and logic integrated

### 4. Key Features Implemented

#### Buy Functionality ✅
- `buyToken(address to)` - Allows users to purchase tokens with ETH
- Uses Chainlink ETH/USD price feed (Sepolia testnet: `0x694AA1769357215DE4FAC081bf1f309aDC325306`)
- Converts ETH sent to equivalent token amount
- **NEW**: 10% fee automatically deducted from purchased amount
- Mints tokens directly to recipient address (minus fees)

#### Sell Functionality ✅
- `sellToken(address to, uint256 amount)` - Allows users to sell tokens back for ETH
- Burns tokens from caller
- Calculates ETH equivalent based on current price
- **NEW**: 15% fee automatically deducted from ETH proceeds
- Transfers ETH to recipient address (minus fees)
- Includes liquidity checks

#### Fee System ✅ (NEW)
- `buy_fee = 10` (10% fee on purchases)
- `sell_fee = 15` (15% fee on sales)
- `fee_pricision = 100` (basis points for calculations)
- Automatic fee calculation and deduction
- Enhanced token economics for platform sustainability

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
1. `9f3534f` - Removed uneeded checks (gas optimization)
2. `8536e84` - **NEW**: Added fee to the stable contract
3. `9367c57` - Created a doc for the engine
4. `2974dc6` - Added comment where needed
5. `c7f7bc4` - Implement reset start and claim function
6. `5db5b84` - Added commnet for readability
7. `bb8361a` - Added the pickWinner funtions
8. `17c5b2d` - Refactored engine logic
9. `21a408a` - Added nuy ticket functions
10. `f99d66b` - Implement the basic of entering the raffles

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

## Recent Completed Tasks (January 2026)
✅ **Fee System Implementation**: Successfully added buy/sell fees to token contract
✅ **Code Optimization**: Removed unnecessary checks for gas efficiency
✅ **Documentation Updates**: Enhanced engine documentation with new features
✅ **Prize Pool Management**: Improved token locking and unlocking mechanisms
✅ **Enhanced Comments**: Added comprehensive code comments for readability

## Dependencies
- **OpenZeppelin Contracts**: For ERC20 token standard implementation
- **Chainlink Contracts**: For price feed integration
- **Foundry**: For development, testing, and deployment

## Deployment Information
- **Network**: Currently configured for Sepolia testnet
- **Price Feed**: ETH/USD AggregatorV3Interface
- **Compiler**: Solidity ^0.8.19

---
*Documentation updated on January 19, 2026*
*Recent Changes: Fee system implementation, code optimization, enhanced documentation*