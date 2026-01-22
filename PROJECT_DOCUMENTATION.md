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

### 2. Complete VRF Integration ✅ (NEW - January 22, 2026)
- **Chainlink VRF V2Plus**: Full integration for verifiable random number generation
- **Automated Winner Selection**: `fulfillRandomWords()` callback handles winner selection automatically
- **Subscription Management**: Automated VRF subscription creation and funding
- **Consumer Registration**: Engine automatically registered as VRF consumer
- **Network Support**: Works on both Anvil (local) and Sepolia (testnet)

### 3. Fee System Implementation ✅ (January 2026)
- **Buy Fee**: 10% fee on all token purchases
- **Sell Fee**: 15% fee on all token sales
- **Fee Precision**: 100 basis points for accurate calculations
- **Automatic Deduction**: Fees automatically deducted during transactions
- **Enhanced Logic**: Improved token minting and burning with fee considerations

### 4. Core Token Implementation ✅
- **Contract**: `StableToken.sol` (146 lines)
- **Inheritance**: Extends OpenZeppelin's ERC20 and Ownable
- **Token Name**: "FortuneFlip"
- **Token Symbol**: "FLIP"
- **License**: MIT
- **Features**: Fee system, Chainlink price feed integration, ETH pegging

### 5. Key Features Implemented

#### Token Exchange System ✅
- **Buy Functionality**: `buyToken(address to)` - Purchase tokens with ETH (10% fee)
- **Sell Functionality**: `sellToken(address to, uint256 amount)` - Sell tokens for ETH (15% fee)
- **Chainlink Integration**: ETH/USD price feed for accurate token valuation
- **Fee System**: Automatic fee deduction with 100 basis point precision
- **Security**: Comprehensive input validation and liquidity checks

#### Raffle Engine System ✅ (NEW - Complete Implementation)
- **Contract**: `RaffileEngine.sol` (374 lines) - Main raffle management contract
- **VRF Integration**: Complete Chainlink VRF V2Plus integration for verifiable randomness
- **Ticket System**: Convert tokens to raffle tickets (5 tokens per ticket)
- **Raffle Entry**: Enter raffles with tickets (max 10 tickets per round)
- **Winner Selection**: Automated winner selection via VRF callbacks
- **Reward System**: Prize pool management and automatic reward distribution

#### VRF Randomness System ✅ (NEW - January 22, 2026)
- **Request Function**: `requestRandomWords()` - Request verifiable random numbers
- **Callback Function**: `fulfillRandomWords()` - Automatic winner selection on VRF response
- **Subscription Management**: Automated VRF subscription creation and funding
- **Consumer Registration**: Engine automatically registered as VRF consumer
- **Network Support**: Works on Anvil (local) and Sepolia (testnet)

#### Deployment & Configuration ✅ (NEW - January 22, 2026)
- **Deploy Script**: `DeployEngine.s.sol` - Automated contract deployment
- **Configuration**: `EngineConfig.s.sol` - Network-specific parameter management
- **Multi-Network**: Support for Anvil and Sepolia with extensible design
- **VRF Setup**: Automated VRF coordinator and LINK token deployment for local testing
- **Ownership Transfer**: StableToken ownership automatically transferred to engine

#### Security Measures ✅
- Custom error definitions for gas efficiency
- Input validation modifiers for all external functions
- Protection against zero addresses and zero amounts
- Liquidity validation for sell operations
- Access control for sensitive operations

### 6. Price Integration ✅
- Chainlink AggregatorV3Interface integration
- Real-time ETH/USD price fetching
- Precision handling for price calculations
- Constants for scaling (`PRECISION = 1e10`, `PRICE_PRECISION = 1e18`)
- Sepolia testnet price feed: `0x694AA1769357215DE4FAC081bf1f309aDC325306`

### 7. Git History
Recent commits show progressive development:
1. `b6f07c8` - Formatted the deploy script for readability
2. `1076420` - Fixed Chainlink dirty error handling
3. `fa1ce5f` - Test deployment and VRF integration
4. `748af16` - **NEW**: Implemented Chainlink VRF functionality
5. `6afb2ec` - Updated documentation
6. `d50be8e` - Implemented deploy script core function
7. `27f6346` - Implemented engine params config for engine
8. `b1873fa` - Added the basic feature of engine config
9. `a7fe978` - Set up script for integration tests
10. `43b139f` - Fixed typos and improved code quality

## Current Status & Issues

### ✅ Resolved Issues
- **VRF Integration**: Complete Chainlink VRF implementation with automated winner selection
- **Deployment Automation**: Comprehensive deployment scripts with network configuration
- **Error Handling**: Fixed Chainlink dirty error handling issues
- **Code Organization**: Formatted deployment scripts for better readability

### Known Issues (from noteSelf.md)
- **Withdrawal Logic Issue**: There's a problem with the sell token logic where users are paid based on price drops - needs investigation
- **Pegging**: Token is not yet tightly pegged to ETH as intended
- **Complexity**: Developer wants to make the system more complex before fixing the withdrawal issue

### Technical Debt
- Price feed address is hardcoded (Sepolia testnet) - **PARTIALLY ADDRESSED** via EngineConfig system
- No admin functions for contract management
- No emergency pause mechanisms
- Limited error handling for edge cases - **IMPROVED** with comprehensive error definitions

## Next Steps (Based on noteSelf.md)
1. Fix the withdrawal logic issue related to price drop payments
2. Implement proper ETH pegging mechanism
3. Add complexity to the system as planned
4. Consider adding admin functions and security features
5. **NEW**: Add comprehensive test suite for VRF functionality
6. **NEW**: Implement VRF request automation on raffle close

## Recent Completed Tasks (January 2026)
✅ **Complete VRF Integration**: Full Chainlink VRF V2Plus implementation with automated winner selection
✅ **Deployment Automation**: Comprehensive deployment scripts with network configuration
✅ **Code Optimization**: Removed unnecessary checks for gas efficiency
✅ **Documentation Updates**: Enhanced project and engine documentation
✅ **Error Handling**: Fixed Chainlink integration issues and improved error management
✅ **Configuration System**: Built robust network configuration management
✅ **Fee System Implementation**: Successfully added buy/sell fees to token contract
✅ **Prize Pool Management**: Improved token locking and unlocking mechanisms
✅ **Enhanced Comments**: Added comprehensive code comments for readability

## Dependencies
- **OpenZeppelin Contracts**: For ERC20 token standard implementation
- **Chainlink Contracts**: For price feed integration
- **Foundry**: For development, testing, and deployment

## Deployment Information
- **Networks**: Anvil (local), Sepolia (testnet) - extensible for mainnet
- **Price Feed**: ETH/USD AggregatorV3Interface (Sepolia: `0x694AA1769357215DE4FAC081bf1f309aDC325306`)
- **VRF Coordinator**: Chainlink VRF V2Plus (network-specific)
- **Compiler**: Solidity ^0.8.19
- **Deployment**: Automated via `DeployEngine.s.sol` script
- **Configuration**: Network-specific parameters via `EngineConfig.s.sol`

## Project Structure (Updated)
```
tiket/
├── src/
│   ├── StableToken.sol          # ERC20 token with fee system
│   └── engine.sol               # Raffle engine with VRF integration
├── script/
│   ├── deploy.s.sol             # Automated deployment script
│   └── config.s.sol             # Network configuration management
├── foundry.toml                 # Foundry configuration
├── foundry.lock                 # Dependency lock file
├── lib/                         # External dependencies
│   ├── openzeppelin-contracts/  # ERC20 and access control
│   └── chainlink-brownie-contracts/ # Price feeds and VRF
├── out/                         # Compiled contract artifacts
├── cache/                       # Build cache
└── docs/                        # Project documentation
    ├── PROJECT_DOCUMENTATION.md
    ├── RAFFLE_ENGINE_DOCUMENTATION.md
    └── audit_status.md
```

---
*Documentation updated on January 22, 2026*
*Recent Changes: Complete VRF integration, deployment automation, enhanced documentation*