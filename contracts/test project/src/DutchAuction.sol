// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DutchAuction
 * @dev A Dutch auction contract for selling a single ERC-721 token
 * Features:
 * - Price decreases linearly from starting price to reserve price
 * - First buyer wins the auction
 * - No refunds allowed once purchased
 * - Pull-payment pattern for auction proceeds
 * - Events for all state changes
 */
contract DutchAuction is ReentrancyGuard, Ownable {
    // State variables
    IERC721 public immutable nftContract;
    uint256 public immutable tokenId;
    uint256 public immutable startingPrice;
    uint256 public immutable reservePrice;
    uint256 public immutable startTime;
    uint256 public immutable duration;
    
    address public winner;
    uint256 public finalPrice;
    bool public auctionEnded;
    
    // Pull payment mapping
    mapping(address => uint256) public pendingWithdrawals;
    
    // Events
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
    
    // Custom errors
    error AuctionNotStarted();
    error AuctionAlreadyEnded();
    error InsufficientPayment();
    error AuctionStillActive();
    error NoFundsToWithdraw();
    error WithdrawalFailed();
    error InvalidParameters();
    
    /**
     * @dev Constructor to initialize the Dutch auction
     * @param _nftContract Address of the ERC-721 contract
     * @param _tokenId Token ID to be auctioned
     * @param _startingPrice Starting price in wei
     * @param _reservePrice Reserve price in wei (minimum price)
     * @param _duration Duration of the auction in seconds
     */
    constructor(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _reservePrice,
        uint256 _duration
    ) Ownable(msg.sender) {
        if (_nftContract == address(0)) revert InvalidParameters();
        if (_startingPrice <= _reservePrice) revert InvalidParameters();
        if (_duration == 0) revert InvalidParameters();
        
        nftContract = IERC721(_nftContract);
        tokenId = _tokenId;
        startingPrice = _startingPrice;
        reservePrice = _reservePrice;
        duration = _duration;
        startTime = block.timestamp;
        
        emit AuctionStarted(
            _nftContract,
            _tokenId,
            _startingPrice,
            _reservePrice,
            startTime,
            _duration
        );
    }
    
    /**
     * @dev Calculate the current price based on time elapsed
     * @return Current price in wei
     */
    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return startingPrice;
        }
        
        if (block.timestamp >= startTime + duration || auctionEnded) {
            return reservePrice;
        }
        
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 priceDecline = ((startingPrice - reservePrice) * timeElapsed) / duration;
        
        return startingPrice - priceDecline;
    }
    
    /**
     * @dev Purchase the NFT at the current price
     */
    function purchase() external payable nonReentrant {
        if (auctionEnded) revert AuctionAlreadyEnded();
        if (block.timestamp < startTime) revert AuctionNotStarted();
        
        uint256 currentPrice = getCurrentPrice();
        
        if (msg.value < currentPrice) revert InsufficientPayment();
        
        // Set auction state
        winner = msg.sender;
        finalPrice = currentPrice;
        auctionEnded = true;
        
        // Add funds to seller's pending withdrawals (pull pattern)
        pendingWithdrawals[owner()] += currentPrice;
        
        // Refund excess payment to buyer
        if (msg.value > currentPrice) {
            pendingWithdrawals[msg.sender] += (msg.value - currentPrice);
        }
        
        // Transfer the NFT to the buyer
        nftContract.transferFrom(owner(), msg.sender, tokenId);
        
        emit Purchase(msg.sender, currentPrice, block.timestamp);
        emit AuctionEnded(msg.sender, currentPrice, block.timestamp);
    }
    
    /**
     * @dev Withdraw pending payments (pull pattern)
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert NoFundsToWithdraw();
        
        pendingWithdrawals[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // Restore the amount if transfer failed
            pendingWithdrawals[msg.sender] = amount;
            revert WithdrawalFailed();
        }
        
        emit WithdrawalMade(msg.sender, amount);
    }
    
    /**
     * @dev End auction manually (only owner, only if time has passed)
     */
    function endAuction() external onlyOwner {
        if (auctionEnded) revert AuctionAlreadyEnded();
        if (block.timestamp < startTime + duration) revert AuctionStillActive();
        
        auctionEnded = true;
        emit AuctionEnded(address(0), 0, block.timestamp);
    }
    
    /**
     * @dev Get the time remaining in the auction
     * @return Time remaining in seconds (0 if auction has ended)
     */
    function getTimeRemaining() external view returns (uint256) {
        if (auctionEnded || block.timestamp >= startTime + duration) {
            return 0;
        }
        return (startTime + duration) - block.timestamp;
    }
    
    /**
     * @dev Check if auction is active
     * @return True if auction is active
     */
    function isAuctionActive() external view returns (bool) {
        return !auctionEnded && 
               block.timestamp >= startTime && 
               block.timestamp < startTime + duration;
    }
    
    /**
     * @dev Get auction info
     * @return All relevant auction information
     */
    function getAuctionInfo() external view returns (
        address nftContractAddr,
        uint256 nftTokenId,
        uint256 startPrice,
        uint256 reservePrice_,
        uint256 startTime_,
        uint256 duration_,
        uint256 currentPrice,
        bool isActive,
        address winner_,
        uint256 finalPrice_
    ) {
        return (
            address(nftContract),
            tokenId,
            startingPrice,
            reservePrice,
            startTime,
            duration,
            getCurrentPrice(),
            this.isAuctionActive(),
            winner,
            finalPrice
        );
    }
}