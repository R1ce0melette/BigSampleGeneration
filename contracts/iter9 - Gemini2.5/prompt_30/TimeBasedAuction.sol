// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(uint256 _biddingTimeInMinutes) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + (_biddingTimeInMinutes * 1 minutes);
    }

    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > highestBid, "There is already a higher bid.");

        if (highestBidder != address(0)) {
            // Refund the previous highest bidder
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;
        if (highestBidder != address(0)) {
            payable(owner).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // No bids were placed
            emit AuctionEnded(address(0), 0);
        }
    }

    function withdraw() public {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "You have not placed any bids.");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");
        
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
