// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeAuction {
    address public seller;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public pendingReturns;

    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _biddingTime) {
        seller = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There is already a higher bid.");

        if (highestBidder != address(0)) {
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
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!auctionEnded, "auctionEnd has already been called.");

        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        if (highestBidder != address(0)) {
            payable(seller).transfer(highestBid);
        } else {
            // No bids, nothing to do
        }
    }
}
