// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address payable public owner;
    string public itemName;
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;
    bool public auctionEnded;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    constructor(string memory _itemName, uint256 _durationInSeconds) {
        owner = payable(msg.sender);
        itemName = _itemName;
        auctionEndTime = block.timestamp + _durationInSeconds;
    }

    function placeBid() public payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > highestBid, "There is already a higher or equal bid.");
        
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
            owner.transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // No bids were placed
            emit AuctionEnded(address(0), 0);
        }
    }

    function getHighestBid() public view returns (address, uint256) {
        return (highestBidder, highestBid);
    }
}
