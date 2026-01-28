# API Reference

## StableToken Contract

### Core Functions

#### `buyToken(address to) external payable returns (bool)`
Converts ETH to StableToken and mints to recipient.

**Parameters:**
- `to`: Address to receive minted tokens

**Returns:**
- `success`: True if operation succeeded

**Events:**
- `TokensBought(address indexed user, uint256 ethAmount)`

#### `sellToken(address to, uint256 amount) external returns (bool)`
Sells StableToken for ETH and burns tokens.

**Parameters:**
- `to`: Address to receive ETH proceeds
- `amount`: Amount of tokens to sell

**Returns:**
- `success`: True if operation succeeded

**Events:**
- `TokensSold(address indexed user, uint256 tokenAmount)`

#### `removeLiquidity() external`
Withdraws all ETH liquidity from contract (owner only).

**Events:**
- None (ETH transfer visible in blockchain)

### View Functions

#### `getAndConvertEthPrice(uint256 ethAmount) external view returns (uint256)`
Converts ETH amount to equivalent tokens.

#### `convertUSDToEth(uint256 tokenAmount) external view returns (uint256)`
Converts token amount to equivalent ETH.

#### `getBuyFee() external pure returns (uint256)`
Returns buy fee in basis points (1000 = 10%).

#### `getSellFee() external pure returns (uint256)`
Returns sell fee in basis points (1500 = 15%).

## RaffleEngine Contract

### Core Functions

#### `buyTickets(uint256 tokenAmount) external`
Buys raffle tickets using StableToken.

**Parameters:**
- `tokenAmount`: Amount of StableToken to spend

**Events:**
- `UserBuyTickets(address indexed user, uint256 amount)`

#### `enterRaffle(uint256 ticketsToUse) external`
Enters current raffle round using tickets.

**Parameters:**
- `ticketsToUse`: Number of tickets to use

**Requirements:**
- Raffle must be open
- User must have sufficient ticket balance
- Must not exceed max tickets per round

**Events:**
- `UserEnterRaffle(address indexed user, uint256 amount)`

#### `claimRewardWon(uint256 _roundId) external`
Claims reward for winning a raffle round.

**Parameters:**
- `_roundId`: ID of round to claim from

**Requirements:**
- Caller must be the winner
- Reward must not have been claimed

**Events:**
- `RewardClaimed(address indexed winner, uint256 amount)`

#### `buyRaffileToken() external payable`
Buys StableToken using ETH.

**Events:**
- `UserBuyToken(address indexed user, uint256 amount)`

#### `sellRaffileToken(uint256 value) external`
Sells StableToken for ETH.

**Parameters:**
- `value`: Amount of StableToken to sell

**Events:**
- `UserSellToken(address indexed user, uint256 amount)`

### Automation Functions

#### `checkUpKeep(bytes calldata callData) external view returns (bool, bytes)`
Checks if automated upkeep is needed.

**Returns:**
- `upkeepNeeded`: True if conditions are met
- `performData`: Data to pass to performUpkeep

#### `performUpkeep(bytes calldata performData) external`
Performs automated raffle winner selection.

**Requirements:**
- Must be called when upkeep is needed

**Events:**
- `RandomWordsRequested(uint256 indexed requestId)`

### View Functions

#### `getRaffleId() external view returns (uint256)`
Returns current raffle round ID.

#### `getEntranceFee() external view returns (uint256)`
Returns cost per raffle ticket in StableToken.

#### `getMaxTicketsPerRound() external view returns (uint256)`
Returns maximum tickets per user per round.

#### `getCurrentState() external view returns (RaffleState)`
Returns current raffle state (Open/Closed).

#### `getTicketBalance(address user) external view returns (uint256)`
Returns ticket balance for specified user.

#### `getRoundTotalTickets(uint256 _roundId) external view returns (uint256)`
Returns total tickets sold in specified round.

#### `getRoundPrizePool(uint256 _roundId) external view returns (uint256)`
Returns prize pool amount for specified round.

#### `getRoundWinner(uint256 _roundId) external view returns (address)`
Returns winner address for specified round.

#### `getTicketsUsedPerRound(uint256 _roundId, address user) external view returns (uint256)`
Returns tickets used by user in specified round.

#### `getRewardClaimed(uint256 _roundId) external view returns (bool)`
Returns whether reward has been claimed for specified round.

#### `getTotalLockedTokens() external view returns (uint256)`
Returns total tokens locked across active rounds.

## Events Reference

### StableToken Events
```solidity
event TokensBought(address indexed user, uint256 ethAmount);
event TokensSold(address indexed user, uint256 tokenAmount);
```

### RaffleEngine Events
```solidity
event UserBuyTickets(address indexed user, uint256 amount);
event UserEnterRaffle(address indexed user, uint256 amount);
event RoundWinnerPicked(uint256 indexed roundId, address indexed winner);
event RewardClaimed(address indexed winner, uint256 amount);
event RandomWordsRequested(uint256 indexed requestId);
```

## Error Codes

### Common Errors
- `Address__ZeroAddress()`: Address parameter is zero
- `Amount__ZeroAmount()`: Amount parameter is zero
- `Auth__Unauthorized()`: Caller not authorized
- `ExternalCall__Reverted()`: External call failed

### StableToken Errors
- `StableToken__InsufficientBalance()`: Insufficient token balance
- `StableToken__NoEnoughLiquidity()`: Insufficient ETH liquidity
- `StableToken__FailedToTransferEth()`: ETH transfer failed

### RaffleEngine Errors
- `RaffileEngine__RaffleIsClosed()`: Raffle is closed for entries
- `RaffileEngine__InsufficientTicketBalance()`: Insufficient tickets
- `RaffileEngine__TicketExeedMaxAllowedPerRound()`: Too many tickets
- `RaffileEngine__YouAreNotTheWinner()`: Not the round winner
- `RaffileEngine__RewardAlreadyClaimed()`: Reward already claimed

## Configuration Parameters

### Network Configurations
- **Entrance Fee**: Configurable per deployment
- **Max Tickets Per Round**: 10 tickets
- **Raffle Interval**: Configurable per deployment
- **Buy Fee**: 10% (1000 basis points)
- **Sell Fee**: 15% (1500 basis points)

### Chainlink Parameters
- **Price Feed**: ETH/USD AggregatorV3Interface
- **VRF Coordinator**: Network-specific
- **Key Hash**: Network-specific
- **Callback Gas Limit**: 100,000 gas
- **Request Confirmations**: 3 confirmations

## Usage Examples

### Buying Tokens
```solidity
// Buy 1 ETH worth of tokens
stableToken.buyToken{value: 1 ether}(userAddress);
```

### Entering Raffle
```solidity
// Enter with 5 tickets
raffleEngine.enterRaffle(5);
```

### Claiming Reward
```solidity
// Claim reward for round 1
raffleEngine.claimRewardWon(1);
```