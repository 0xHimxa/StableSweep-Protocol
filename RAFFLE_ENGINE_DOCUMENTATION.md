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

### 2. RaffileEngine.sol
- **Purpose**: Main raffle management contract
- **Key Features**:
  - Ticket purchasing system
  - Raffle entry management
  - Winner selection using random numbers
  - Reward claiming mechanism
  - Round-based raffle system

## Core Functionality Implemented

### Token Exchange System
✅ **Completed**: 
- `buyRaffileToken()` - Users can buy tokens with ETH
- `sellRaffileToken()` - Users can sell tokens back for ETH
- Integration with Chainlink ETH/USD price feed for accurate pricing
- Proper error handling and balance checks

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
- Binary search algorithm for efficient winner lookup
- Proper ticket range management
- Automatic round reset after winner selection

### Reward System
✅ **Completed**:
- `claimRewardWon()` - Winners can claim their rewards
- Reward calculation based on total tickets sold
- Secure transfer of rewards to winners
- Winner validation and authorization

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
- Various mappings for tracking balances, winners, and ticket ranges

### Events Emitted
- `UserBuyToken` - Token purchases
- `UserSellToken` - Token sales
- `UserBuyTickets` - Ticket purchases
- `UserEnterRaffle` - Raffle entries
- `RewardWinnerPicked` - Winner selection
- `RewardClaimed` - Reward claims

## Current Status

### ✅ Completed Features
1. Full token exchange system with Chainlink integration
2. Complete ticket purchasing and management
3. Raffle entry system with validation
4. Winner selection algorithm
5. Reward claiming mechanism
6. Round management system
7. Comprehensive error handling
8. Event emission for all major operations

### 🔄 Areas for Future Enhancement
1. **Random Number Generation**: Currently uses external random numbers - could integrate Chainlink VRF for on-chain randomness
2. **Admin Dashboard**: Additional admin functions for system management
3. **Emergency Controls**: Pause/unpause functionality for emergencies
4. **Fee System**: Implementation of platform fees
5. **Multi-Raffle Support**: Concurrent raffle rounds
6. **Advanced Analytics**: On-chain statistics and reporting

## Testing Status

The project structure includes Foundry testing setup, but specific test files need to be created. Recommended test coverage:

- Unit tests for each contract function
- Integration tests for complete user flows
- Edge case testing for error conditions
- Gas optimization testing

## Deployment Considerations

- **Network**: Ethereum mainnet or testnets (Sepolia, Goerli)
- **Chainlink Price Feed**: ETH/USD feed address needs to be updated for target network
- **Initial Liquidity**: Contract needs ETH liquidity for token redemptions
- **Access Control**: Owner address for contract administration

## Usage Flow

1. **Setup**: Deploy StableToken and RaffileEngine contracts
2. **Token Purchase**: Users buy tokens with ETH via `buyRaffileToken()`
3. **Ticket Purchase**: Users convert tokens to tickets via `buyTickets()`
4. **Raffle Entry**: Users enter raffle using tickets via `enterRaffle()`
5. **Winner Selection**: Admin calls `pickWinner()` with random number
6. **Reward Claim**: Winner claims reward via `claimRewardWon()`
7. **Next Round**: System automatically resets for next round

## Conclusion

The Raffle Engine represents a solid foundation for a decentralized raffle platform. The core functionality is complete and operational, with proper security measures and gas optimization in place. The system is ready for testing and deployment, with clear paths for future enhancements and feature additions.

*Last Updated: January 2026*
*Status: Core Implementation Complete*