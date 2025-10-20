// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeAuction {
    address public owner;
    uint256 public deadline;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;
    bool public ended;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event Refunded(address indexed bidder, uint256 amount);

    constructor(uint256 duration) {
        owner = msg.sender;
        deadline = block.timestamp + duration;
    }

    function bid() external payable {
        require(block.timestamp < deadline, "Auction ended");
        require(msg.value > highestBid, "Bid too low");
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() external {
        require(block.timestamp >= deadline, "Auction not ended");
        require(!ended, "Already ended");
        ended = true;
        (bool sent, ) = owner.call{value: highestBid}("");
        require(sent, "Transfer failed");
        emit AuctionEnded(highestBidder, highestBid);
    }

    function refund() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No refund");
        bids[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Refund failed");
        emit Refunded(msg.sender, amount);
    }
}
