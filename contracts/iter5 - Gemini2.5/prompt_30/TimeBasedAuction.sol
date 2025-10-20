// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimeBasedAuction
 * @dev A contract for a time-based auction where the highest bidder wins.
 */
contract TimeBasedAuction {

    address payable public owner;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    constructor(uint256 _biddingTime) {
        owner = payable(msg.sender);
        auctionEndTime = block.timestamp + _biddingTime;
    }

    /**
     * @dev Places a bid on the auction.
     */
    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > highestBid, "There is already a higher bid.");

        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid); // Refund previous highest bidder
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction and transfers the funds to the owner.
     */
    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        owner.transfer(highestBid);
    }
}
