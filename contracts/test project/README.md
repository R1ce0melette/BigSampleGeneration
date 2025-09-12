# Dutch Auction Smart Contract

A Solidity ^0.8.25 contract implementing a Dutch auction for selling a single ERC-721 token with comprehensive security features and extensive test coverage.

## Features

- **Linear Price Decrease**: Price decreases linearly from starting price to reserve price over the auction duration
- **First Buyer Wins**: The first buyer to meet the current price wins the auction
- **No Refunds**: Once purchased, no refunds are allowed (as per requirements)
- **Pull Payment Pattern**: Uses pull-over-push pattern for secure fund withdrawals
- **Comprehensive Events**: Events for all state changes including auction start, purchase, and withdrawal
- **Security**: Reentrancy protection, overflow protection, and comprehensive input validation

## Contract Architecture

### Core Contracts

1. **DutchAuction.sol**: Main auction contract implementing all auction logic
2. **MockNFT.sol**: ERC-721 contract for testing purposes

### Key Features

- **Linear Price Calculation**: `getCurrentPrice()` calculates current price based on time elapsed
- **Secure Purchase**: `purchase()` function with reentrancy protection and proper state management
- **Pull Payments**: `withdraw()` function implements pull payment pattern for security
- **Comprehensive Events**: All state changes emit events for transparency

## Price Curve

The price decreases linearly according to the formula:

```
current_price = starting_price - ((starting_price - reserve_price) * time_elapsed / duration)
```

Where:
- `starting_price`: Initial auction price
- `reserve_price`: Minimum price (auction floor)
- `time_elapsed`: Seconds since auction start
- `duration`: Total auction duration in seconds

## Usage

### Deployment

```solidity
DutchAuction auction = new DutchAuction(
    nftContract,    // Address of ERC-721 contract
    tokenId,        // Token ID to auction
    startingPrice,  // Starting price in wei
    reservePrice,   // Reserve price in wei
    duration        // Auction duration in seconds
);
```

### Purchasing

```solidity
// Check current price
uint256 currentPrice = auction.getCurrentPrice();

// Purchase NFT
auction.purchase{value: currentPrice}();
```

### Withdrawing Funds

```solidity
// Check pending withdrawal
uint256 pending = auction.pendingWithdrawals(msg.sender);

// Withdraw funds
auction.withdraw();
```

## Testing

The project includes comprehensive test suites covering:

### 1. Price Curve Tests (`DutchAuction.t.sol`)
- Linear price decrease verification
- Price calculation at different time points
- Edge cases for start/end timing

### 2. Edge Case Tests (`DutchAuctionEdgeCases.t.sol`)
- Very short/long auctions
- High precision calculations
- Minimal price differences
- Maximum value handling

### 3. Security Tests (`DutchAuctionSecurity.t.sol`)
- Reentrancy attack protection
- Withdrawal security
- Gas limit considerations
- Manipulation resistance

### Running Tests

```bash
# Install dependencies
forge install

# Run all tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test file
forge test --match-contract DutchAuctionTest

# Run tests with gas reporting
forge test --gas-report
```

## Security Features

### Reentrancy Protection
- Uses OpenZeppelin's `ReentrancyGuard`
- Applied to `purchase()` and `withdraw()` functions

### Pull Payment Pattern
- Buyers and sellers must call `withdraw()` to receive funds
- Prevents failed transfers from blocking the auction

### Input Validation
- Constructor validates all parameters
- Runtime checks for auction state and payment amounts

### Access Control
- Uses OpenZeppelin's `Ownable` for admin functions
- Only owner can manually end expired auctions

## Events

```solidity
event AuctionStarted(
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 startingPrice,
    uint256 reservePrice,
    uint256 startTime,
    uint256 duration
);

event Purchase(
    address indexed buyer,
    uint256 price,
    uint256 timestamp
);

event AuctionEnded(
    address indexed winner,
    uint256 finalPrice,
    uint256 timestamp
);

event WithdrawalMade(
    address indexed recipient,
    uint256 amount
);
```

## Gas Optimization

- Immutable variables for gas efficiency
- Minimal storage writes
- Efficient price calculation algorithm

## Requirements Compliance

✅ **Solidity ^0.8.25**: Contract uses exact version  
✅ **Dutch Auction**: Linear price decrease implementation  
✅ **Single ERC-721**: Designed for one NFT per auction  
✅ **Linear Price Decrease**: Mathematical formula implemented  
✅ **Reserve Price**: Price stops at reserve, never goes below  
✅ **First Buyer Wins**: First successful purchase ends auction  
✅ **No Refunds**: No refund mechanism implemented  
✅ **Pull Payment**: Secure withdrawal pattern implemented  
✅ **Events**: Comprehensive event logging  
✅ **Foundry Tests**: Extensive test suite covering all requirements  

## Test Coverage

- **Price Curve**: Tests linear decrease, edge timings, precision
- **Edge Block Timing**: Tests exact start/end block scenarios
- **Refund Safety**: Verifies no refund mechanisms exist
- **Security**: Reentrancy, overflow, and manipulation protection
- **Events**: All events properly emitted
- **Edge Cases**: Boundary conditions and error scenarios

## Development Setup

```bash
# Clone and setup
git clone <repo>
cd dutch-auction

# Install Foundry dependencies
forge install openzeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std

# Build contracts
forge build

# Run tests
forge test

# Deploy (testnet)
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## License

MIT License - see LICENSE file for details.