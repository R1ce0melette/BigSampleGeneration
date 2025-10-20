// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimeBasedAuction
 * @dev A contract for a simple time-based auction.
 */
contract TimeBasedAuction {
    address public seller;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function.");
        _;
    }

    modifier auctionIsRunning() {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        _;
    }

    /**
     * @dev Sets up the auction with a bidding duration.
     * @param _biddingTime The duration of the auction in seconds.
     */
    constructor(uint256 _biddingTime) {
        seller = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    /**
     * @dev Allows a user to place a bid.
     * Bids must be higher than the current highest bid.
     */
    function bid() external payable auctionIsRunning {
        require(msg.value > highestBid, "Your bid must be higher than the current highest bid.");
        
        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            (bool success, ) = payable(highestBidder).call{value: highestBid}("");
            require(success, "Failed to refund previous bidder.");
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction and transfers the highest bid to the seller.
     * Can only be called after the auction deadline has passed.
     */
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;

        if (highestBidder != address(0)) {
            (bool success, ) = payable(seller).call{value: highestBid}("");
            require(success, "Failed to transfer funds to seller.");
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // No bids were placed
            emit AuctionEnded(address(0), 0);
        }
    }

    /**
     * @dev Allows a bidder to withdraw their bid if they are not the highest bidder
     * and the auction has ended. This is a fallback in case endAuction is not called.
     */
    function withdraw() external {
        require(block.timestamp >= auctionEndTime, "Auction is still running.");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");
        
        uint256 amount = bids[msg.sender];
        require(amount > 0, "You have not placed a bid.");

        bids[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed.");
    }
}
