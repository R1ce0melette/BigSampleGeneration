// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    uint256 public auctionEndTime;
    
    address public highestBidder;
    uint256 public highestBid;

    bool public auctionEnded;

    mapping(address => uint256) public pendingReturns;

    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _biddingTimeInSeconds) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTimeInSeconds;
    }

    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There is already a higher bid.");

        if (highestBidder != address(0)) {
            // Refund the previous highest bidder
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                // If send fails, re-credit the user's pending returns
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        if (highestBidder != address(0)) {
            // Transfer the prize to the owner
            payable(owner).transfer(highestBid);
        } else {
            // No bids were placed
        }
    }
}
