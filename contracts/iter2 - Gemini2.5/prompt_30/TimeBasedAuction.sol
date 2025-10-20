// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeBasedAuction is Ownable {
    string public itemName;
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;
    bool public auctionEnded;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    constructor(string memory _itemName, uint256 _durationInMinutes) Ownable(msg.sender) {
        itemName = _itemName;
        auctionEndTime = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    /**
     * @dev Allows a user to place a bid in the auction.
     */
    function placeBid() public payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > highestBid, "There is already a higher or equal bid.");
        
        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction, transferring the item's proceeds to the owner.
     *      This can be called by anyone after the auction deadline.
     */
    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;

        if (highestBidder != address(0)) {
            // Transfer the highest bid to the contract owner
            payable(owner()).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // No bids were placed
            emit AuctionEnded(address(0), 0);
        }
    }

    /**
     * @dev Allows bidders to withdraw their bids if they are not the highest bidder
     *      after the auction has ended. This is a fallback in case the automatic
     *      refund in placeBid fails or is not used.
     */
    function withdraw() public {
        require(auctionEnded, "Auction is still active.");
        uint256 amount = bids[msg.sender];
        require(amount > 0, "You did not place a bid.");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
