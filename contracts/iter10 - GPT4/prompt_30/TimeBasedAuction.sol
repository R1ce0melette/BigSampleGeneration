// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    uint256 public endTime;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;
    bool public ended;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 duration) {
        require(duration > 0, "Duration required");
        owner = msg.sender;
        endTime = block.timestamp + duration;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "Auction ended");
        require(msg.value > highestBid, "Bid too low");
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit BidPlaced(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds");
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() external onlyOwner {
        require(block.timestamp >= endTime, "Auction not ended");
        require(!ended, "Already ended");
        ended = true;
        if (highestBidder != address(0)) {
            payable(owner).transfer(highestBid);
        }
        emit AuctionEnded(highestBidder, highestBid);
    }
}
