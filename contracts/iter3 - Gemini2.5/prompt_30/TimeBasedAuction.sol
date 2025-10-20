// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimeBasedAuction
 * @dev A contract for a time-based auction. Bids are accepted until a deadline,
 * and the highest bidder wins and can claim the item (represented by ETH withdrawal).
 */
contract TimeBasedAuction {
    address public seller;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public pendingReturns;

    /**
     * @dev Emitted when a new highest bid is placed.
     * @param bidder The address of the new highest bidder.
     * @param amount The amount of the new highest bid.
     */
    event NewHighestBid(address indexed bidder, uint256 amount);

    /**
     * @dev Emitted when the auction ends.
     * @param winner The address of the winner.
     * @param amount The winning bid amount.
     */
    event AuctionEnded(address indexed winner, uint256 amount);

    /**
     * @dev Modifier to ensure the auction is still active.
     */
    modifier auctionIsActive() {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        _;
    }

    /**
     * @dev Sets up the auction with a specified bidding duration.
     * @param _biddingTime The duration of the auction in seconds.
     */
    constructor(uint256 _biddingTime) {
        require(_biddingTime > 0, "Bidding time must be greater than zero.");
        seller = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    /**
     * @dev Allows a user to place a bid.
     * The bid must be higher than the current highest bid.
     * The previous highest bidder's funds are marked for return.
     */
    function bid() public payable auctionIsActive {
        require(msg.value > highestBid, "Your bid must be higher than the current highest bid.");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewHighestBid(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction. Can be called by anyone after the deadline.
     * The funds are transferred to the seller.
     */
    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!auctionEnded, "Auction has already been finalized.");

        auctionEnded = true;
        
        if (highestBidder != address(0)) {
            payable(seller).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            // No bids were placed
            emit AuctionEnded(address(0), 0);
        }
    }

    /**
     * @dev Allows outbid bidders to withdraw their funds.
     * @return A boolean indicating whether the withdrawal was successful.
     */
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                // If send fails, revert the state change and the transaction
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Returns the current highest bid and the bidder.
     */
    function getHighestBid() public view returns (address, uint256) {
        return (highestBidder, highestBid);
    }

    /**
     * @dev Returns the time remaining until the auction ends.
     */
    function getTimeRemaining() public view returns (uint256) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        }
        return auctionEndTime - block.timestamp;
    }
}
