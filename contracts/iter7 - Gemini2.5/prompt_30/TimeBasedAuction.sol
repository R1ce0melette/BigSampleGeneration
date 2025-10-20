// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimeBasedAuction
 * @dev A contract for a time-based auction. The highest bidder at the end wins.
 */
contract TimeBasedAuction {
    address payable public seller;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;

    /**
     * @dev Emitted when a new bid is placed.
     * @param bidder The address of the bidder.
     * @param amount The amount of the bid.
     */
    event NewBid(address indexed bidder, uint256 amount);

    /**
     * @dev Emitted when the auction ends.
     * @param winner The address of the winner.
     * @param amount The winning bid amount.
     */
    event AuctionEnded(address indexed winner, uint256 amount);

    /**
     * @dev Sets up the auction with the seller and the duration.
     * @param _auctionDurationInMinutes The duration of the auction in minutes.
     */
    constructor(uint256 _auctionDurationInMinutes) {
        seller = payable(msg.sender);
        auctionEndTime = block.timestamp + (_auctionDurationInMinutes * 1 minutes);
    }

    /**
     * @dev Allows a user to place a bid.
     * Bids must be higher than the current highest bid.
     * The bid amount is held in the contract until the auction ends.
     */
    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > highestBid, "Your bid must be higher than the current highest bid.");

        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            (bool success, ) = payable(highestBidder).call{value: highestBid}("");
            require(success, "Failed to refund previous bidder.");
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction. Can be called by anyone after the deadline.
     * The funds are transferred to the seller, and the auction is marked as ended.
     */
    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;

        if (highestBidder != address(0)) {
            (bool success, ) = seller.call{value: highestBid}("");
            require(success, "Failed to transfer funds to the seller.");
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // If no bids were placed, just end the auction.
            emit AuctionEnded(address(0), 0);
        }
    }

    /**
     * @dev Allows bidders who did not win to withdraw their bids after the auction has ended.
     * This function is not strictly necessary if refunds are handled during bidding,
     * but it's a good practice for robustness.
     */
    function withdraw() public {
        require(auctionEnded, "Auction is still ongoing.");
        uint256 amount = bids[msg.sender];
        require(amount > 0, "You did not place a bid.");
        require(msg.sender != highestBidder, "The winner cannot withdraw their bid.");

        bids[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed.");
    }
}
