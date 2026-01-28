# Raffle Engine Documentation

## Project Overview

The Raffle Engine is a decentralized raffle system built on Ethereum using Solidity. This project implements a complete raffle ecosystem where users can purchase tokens, buy raffle tickets, enter raffles, and claim rewards - all managed through smart contracts.

## Architecture

The system consists of two main contracts:

### 1. StableToken.sol
- **Purpose**: ERC20 token contract that represents the stable currency used in the raffle system
- **Token Name**: FortuneFlip (Flip)
- **Key Features**:
  - ETH to token conversion using Chainlink price feeds
  - Token to ETH conversion (sell functionality)
  - Pegged to ETH value via Chainlink ETH/USD price feed
  - Ownable contract with admin controls
  - **NEW**: Fee system implementation (10% buy fee, 15% sell fee)
  - **NEW**: Automatic fee deduction during token transactions

### 2. RaffileEngine.sol
- **Purpose**: Main raffle management contract
- **Key Features**:
  - Ticket purchasing system
  - Raffle entry management
  - Winner selection using random numbers
  - Reward claiming mechanism
  - Round-based raffle system
  - **NEW**: Enhanced prize pool management with token locking
  - **NEW**: Total locked tokens tracking across rounds
  - **NEW**: Automatic token unlocking on reward claims

## Core Functionality Implemented

### Token Exchange System
✅ **Completed**: 
- `buyRaffileToken()` - Users can buy tokens with ETH (10% fee applied)
- `sellRaffileToken()` - Users can sell tokens back for ETH (15% fee applied)
- Integration with Chainlink ETH/USD price feed for accurate pricing
- Proper error handling and balance checks
- **NEW**: Automatic fee deduction during transactions
- **NEW**: Enhanced fee calculation with precision handling

### Ticket Management
✅ **Completed**:
- `buyTickets()` - Convert tokens to raffle tickets
- Fixed entrance fee of 5 tokens per ticket
- Ticket balance tracking per user
- Proper token transfer and validation

### Raffle System
✅ **Completed**:
- `enterRaffle()` - Users can enter raffles using tickets
- Maximum 10 tickets per user per round
- Ticket range assignment for fair winner selection
- Round-based raffle management with Open/Closed states

### Winner Selection
✅ **Completed**:
- `pickWinner()` - Random winner selection using external random number
- `requestRandomWords()` - Chainlink VRF integration for verifiable randomness
- `fulfillRandomWords()` - VRF callback handling
- Binary search algorithm for efficient winner lookup
- Proper ticket range management
- Automatic round reset after winner selection
- **Note**: VRF integration is basic - winner selection still uses external random numbers

### Reward System
✅ **Completed**:
- `claimRewardWon()` - Winners can claim their rewards
- Reward calculation based on total tickets sold
- Secure transfer of rewards to winners
- Winner validation and authorization
- **NEW**: Automatic prize pool management and token unlocking
- **NEW**: Enhanced tracking of locked tokens per round
- **NEW**: Proper token flow from ticket purchases to reward claims

## Technical Implementation Details

### Security Features
- Comprehensive error handling with custom errors
- Input validation for all external functions
- Reentrancy protection through proper state management
- Access control for sensitive operations

### Gas Optimization
- Efficient data structures for ticket ranges
- Binary search for winner selection (O(log n) complexity)
- Minimal storage operations where possible
- Proper event emission for off-chain tracking

### Data Structures
- `TicketRange` struct for tracking ticket ownership
- Mapping-based storage for user balances and round data
- Array-based ticket range management per round

## State Management

### Key State Variables
- `raffleId`: Current raffle round identifier
- `entranceFee`: Fixed cost per ticket (5 tokens)
- `maxTicketsPerRound`: Maximum tickets per user (10)
- `currentState`: Raffle state (Open/Closed)
- `roundPrizePool`: Tokens locked per raffle round
- `totalLockedTokens`: Total tokens locked across all rounds
- Various mappings for tracking balances, winners, and ticket ranges

### Events Emitted
- `UserBuyToken` - Token purchases
- `UserSellToken` - Token sales
- `UserBuyTickets` - Ticket purchases
- `UserEnterRaffle` - Raffle entries
- `RewardWinnerPicked` - Winner selection
- `RewardClaimed` - Reward claims

## Recent Updates (January 2026)

### 🆕 New Features Added
1. **Chainlink VRF Integration**: 
   - Integrated Chainlink VRF V2Plus for on-chain random number generation
   - `requestRandomWords()` function for requesting verifiable random numbers
   - `fulfillRandomWords()` callback for handling VRF responses
   - Subscription-based VRF funding with `topUpSubscription()` function
   - Automatic subscription creation and consumer registration

2. **Fee System Implementation**: 
   - Buy fee: 10% on token purchases
   - Sell fee: 15% on token sales
   - Fee precision: 100 basis points
   - Fees automatically deducted during token transactions

3. **Enhanced Prize Pool Management**:
   - `roundPrizePool` mapping to track tokens locked per raffle round
   - `totalLockedTokens` to monitor all locked tokens across rounds
   - Automatic prize pool accumulation from ticket purchases
   - Proper token unlocking when rewards are claimed

4. **Improved Reward Claiming**:
   - Enhanced `claimRewardWon()` function with proper token management
   - Automatic prize pool reset after reward claims
   - Total locked tokens tracking updates

5. **Code Refinements**:
   - Removed unnecessary checks for gas optimization
   - Added comprehensive comments for better readability
   - Improved error handling with specific error types

### 🚀 Recent Improvements (January 22-23, 2026)

1. **Complete VRF Integration**:
   - **FULLY FUNCTIONAL**: `fulfillRandomWords()` now properly integrates with Chainlink VRF
   - **Winner Selection**: `pickWinner()` function completely removed - VRF callback handles winner selection automatically
   - **Random Number Generation**: No more external random numbers - uses verifiable on-chain randomness
   - **Automated Flow**: VRF request → callback → winner selection → round reset

2. **Enhanced Deployment Script**:
   - **Formatted for Readability**: `DeployEngine.s.sol` refactored for better code organization
   - **Chainlink Error Fixes**: Resolved dirty error handling issues with Chainlink integration
   - **Comprehensive VRF Setup**: Automated subscription creation, consumer registration, and funding
   - **Multi-Network Support**: Proper handling for Anvil (local) and Sepolia (testnet) deployments

3. **Robust Configuration System**:
   - **`EngineConfig.s.sol`**: Network-specific parameter management
   - **Mock Deployment**: Automatic VRF coordinator and LINK token deployment for local testing
   - **Production Ready**: Sepolia testnet configuration with live Chainlink endpoints
   - **Extensible Design**: Easy addition of new networks (Goerli, Mainnet support planned)

4. **Streamlined Contract Architecture**:
   - **Constructor Injection**: All VRF parameters passed through deployment script
   - **Ownership Transfer**: StableToken ownership automatically transferred to RaffileEngine
   - **Dependency Management**: Clean separation between deployment and runtime logic
   - **Error Handling**: Comprehensive error definitions and validation

5. **Development Workflow Enhancements**:
   - **Local Testing**: Complete mock environment for Anvil development
   - **Testnet Deployment**: One-command deployment to Sepolia with proper VRF setup
   - **Subscription Management**: Automated VRF subscription funding and consumer registration
   - **Network Detection**: Automatic configuration based on blockchain ID

6. **Testing & Code Quality Improvements (January 23, 2026)**:
   - **100% Test Coverage**: StableToken contract now has complete test coverage
   - **Integration Tests**: Comprehensive integration tests for StableToken with price feed mocking
   - **Code Formatting**: Entire codebase formatted for consistency and readability
   - **Enhanced Comments**: Added detailed comments throughout the codebase
   - **Price Feed Configuration**: Improved price feed address management in config system
   - **Test Structure**: Well-organized test files with proper mocking and setup

### 🔧 Technical Improvements
- **Random Number Generation**: Migrated from external random numbers to Chainlink VRF for provable randomness
- **Gas Optimization**: Removed redundant validation checks
- **State Management**: Enhanced tracking of locked tokens and prize pools
- **Security**: Maintained robust access controls and validation
- **Documentation**: Added inline comments for complex logic

### 🎯 Current Implementation Status
The raffle system now features **COMPLETE Chainlink VRF integration** with the following capabilities:
- ✅ VRF subscription creation and management
- ✅ Random word request functionality via `requestRandomWords()`
- ✅ **FULLY INTEGRATED**: `fulfillRandomWords()` callback handles winner selection automatically
- ✅ **REMOVED**: `pickWinner()` function - no longer needed with VRF integration
- ✅ **VERIFIABLE RANDOMNESS**: All winner selection uses provably random Chainlink VRF
- ✅ **AUTOMATED FLOW**: VRF request → callback → winner selection → round reset

## Current Status

### ✅ Completed Features
1. Full token exchange system with Chainlink integration and fee structure
2. Complete ticket purchasing and management
3. Raffle entry system with validation
4. **COMPLETE**: Winner selection using fully integrated Chainlink VRF V2Plus
5. Reward claiming mechanism with proper token management
6. Round management system with prize pool tracking
7. Comprehensive error handling
8. Event emission for all major operations
9. Fee system for sustainable platform operations
10. Enhanced token locking and unlocking mechanisms
11. **COMPLETE**: Chainlink VRF V2Plus integration with automated winner selection
12. VRF subscription management and funding capabilities
13. **ENHANCED**: Formatted deployment script with improved readability
14. **ROBUST**: Network configuration system for multi-environment support
15. **STREAMLINED**: Contract initialization and dependency management
16. **FIXED**: Chainlink integration error handling and dirty state issues

### 🔄 Areas for Future Enhancement
1. **✅ COMPLETED**: VRF Integration - Fully functional Chainlink VRF with automated winner selection
2. **Admin Dashboard**: Additional admin functions for system management
3. **Emergency Controls**: Pause/unpause functionality for emergencies
4. **Dynamic Fee System**: Adjustable fees based on market conditions
5. **Multi-Raffle Support**: Concurrent raffle rounds
6. **Advanced Analytics**: On-chain statistics and reporting
7. **Fee Distribution**: Mechanism to distribute collected fees
8. **✅ COMPLETED**: VRF Configuration - VRF parameters configurable via EngineConfig system
9. **✅ COMPLETED**: Deployment Automation - Comprehensive deployment script implemented
10. **✅ COMPLETED**: Multi-Network Support - Network configuration system added
11. **VRF Request Automation**: Auto-trigger VRF requests when raffle closes
12. **✅ COMPLETED**: Enhanced Testing - Comprehensive test suite with 100% coverage for StableToken
13. **✅ COMPLETED**: Integration Tests - Complete integration tests with price feed mocking
14. **✅ COMPLETED**: Code Quality - Formatted codebase with comprehensive comments

## Testing Status

### ✅ Current Test Coverage (January 24, 2026)
- **StableToken Contract**: 100% test coverage (19 tests passed)
- **RaffileEngine Contract**: 90%+ test coverage (24 tests passed)
- **Integration Tests**: Comprehensive integration tests for both contracts
- **Test Files**:
  - `test/intergration/stableToken.t.sol` - Complete StableToken testing
  - `test/intergration/engine.t.sol` - Complete RaffileEngine testing
  - `test/priceMock.sol` - Price feed mocking for testing

### Test Coverage Details
#### StableToken Tests (19/19 ✅)
- Token purchase functionality with fee validation
- Token sale functionality with liquidity checks
- Price conversion and ETH pegging tests
- Error handling for edge cases
- Fee system validation (10% buy, 15% sell)
- Access control and ownership tests

#### RaffileEngine Tests (24/24 ✅)
- Ticket purchasing and validation
- Raffle entry management
- VRF integration and random word requests
- Winner selection and reward claiming
- Token exchange integration
- Error handling for all failure scenarios
- Round management and prize pool tracking

### Test Results Summary
```
╭------------------+--------+--------+---------╮
| Test Suite       | Passed | Failed | Skipped |
+==============================================+
| RaffileEngine    | 24     | 0      | 0       |
|------------------+--------+--------+---------|
| StableToken      | 19     | 0      | 0       |
╰------------------+--------+--------+---------╯
Total: 43 tests passed, 0 failed
```

## Deployment Considerations

- **Network**: Ethereum mainnet or testnets (Sepolia, Goerli)
- **Chainlink Price Feed**: ETH/USD feed address needs to be updated for target network
- **Initial Liquidity**: Contract needs ETH liquidity for token redemptions
- **Access Control**: Owner address for contract administration

## Usage Flow

1. **Setup**: Deploy StableToken and RaffileEngine contracts using `DeployEngine.s.sol`
2. **VRF Configuration**: VRF subscription automatically created and funded during deployment
3. **Token Purchase**: Users buy tokens with ETH via `buyRaffileToken()` (10% fee applied)
4. **Ticket Purchase**: Users convert tokens to tickets via `buyTickets()` (5 tokens per ticket)
5. **Raffle Entry**: Users enter raffle using tickets via `enterRaffle()` (max 10 tickets per round)
6. **Winner Selection**: 
   - Admin calls `requestRandomWords()` to get verifiable random numbers from Chainlink
   - **AUTOMATIC**: `fulfillRandomWords()` callback selects winner and resets round
7. **Reward Claim**: Winner claims reward via `claimRewardWon()` (prize pool automatically unlocked)
8. **Next Round**: System automatically resets for next round after winner selection

## Conclusion

The Raffle Engine represents a solid foundation for a decentralized raffle platform. The core functionality is complete and operational, with proper security measures and gas optimization in place. The system is ready for testing and deployment, with clear paths for future enhancements and feature additions.

*Last Updated: January 24, 2026*
*Status: COMPLETE VRF Integration - 90%+ Engine Test Coverage - 100% StableToken Test Coverage - Production Ready*