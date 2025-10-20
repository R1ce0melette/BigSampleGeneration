// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;
    bool public auctionEnded;

    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier auctionIsRunning() {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        _;
    }

    constructor(uint256 _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() public payable auctionIsRunning {
        require(msg.value > highestBid, "There is already a higher bid.");
        
        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction is still running.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;
        
        if (highestBidder != address(0)) {
            // Transfer the funds to the owner
            payable(owner).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // No bids were placed
            emit AuctionEnded(address(0), 0);
        }
    }

    // In case a user sends ETH directly to the contract without bidding
    function withdraw() public {
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");
        uint256 amount = bids[msg.sender];
        require(amount > 0, "You have not placed any bids.");
        
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
