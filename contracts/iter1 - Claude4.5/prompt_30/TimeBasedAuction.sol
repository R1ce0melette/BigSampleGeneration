// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeBasedAuction
 * @dev A time-based auction where bids are placed before a deadline and the highest bidder wins
 */
contract TimeBasedAuction {
    enum AuctionStatus {
        ACTIVE,
        ENDED,
        CANCELLED
    }
    
    struct Auction {
        uint256 id;
        address payable seller;
        string itemName;
        string description;
        uint256 startingBid;
        uint256 highestBid;
        address payable highestBidder;
        uint256 startTime;
        uint256 endTime;
        AuctionStatus status;
        uint256 totalBids;
        bool sellerWithdrawn;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    uint256 private auctionCounter;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[]) private auctionBids;
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;
    mapping(address => uint256[]) private sellerAuctions;
    mapping(address => uint256[]) private bidderAuctions;
    
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        string itemName,
        uint256 startingBid,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 timestamp
    );
    
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid
    );
    
    event AuctionCancelled(uint256 indexed auctionId, address indexed seller);
    
    event FundsWithdrawn(
        uint256 indexed auctionId,
        address indexed withdrawer,
        uint256 amount
    );
    
    modifier auctionExists(uint256 auctionId) {
        require(auctionId > 0 && auctionId <= auctionCounter, "Auction does not exist");
        _;
    }
    
    modifier auctionActive(uint256 auctionId) {
        require(auctions[auctionId].status == AuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp < auctions[auctionId].endTime, "Auction has ended");
        _;
    }
    
    modifier onlySeller(uint256 auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Only seller can perform this action");
        _;
    }
    
    /**
     * @dev Create a new auction
     * @param itemName Name of the item being auctioned
     * @param description Description of the item
     * @param startingBid Minimum bid amount
     * @param duration Duration of the auction in seconds
     * @return auctionId The ID of the created auction
     */
    function createAuction(
        string memory itemName,
        string memory description,
        uint256 startingBid,
        uint256 duration
    ) external returns (uint256) {
        require(bytes(itemName).length > 0, "Item name cannot be empty");
        require(startingBid > 0, "Starting bid must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        auctionCounter++;
        uint256 auctionId = auctionCounter;
        
        uint256 endTime = block.timestamp + duration;
        
        auctions[auctionId] = Auction({
            id: auctionId,
            seller: payable(msg.sender),
            itemName: itemName,
            description: description,
            startingBid: startingBid,
            highestBid: 0,
            highestBidder: payable(address(0)),
            startTime: block.timestamp,
            endTime: endTime,
            status: AuctionStatus.ACTIVE,
            totalBids: 0,
            sellerWithdrawn: false
        });
        
        sellerAuctions[msg.sender].push(auctionId);
        
        emit AuctionCreated(auctionId, msg.sender, itemName, startingBid, endTime);
        
        return auctionId;
    }
    
    /**
     * @dev Place a bid on an auction
     * @param auctionId The ID of the auction
     */
    function placeBid(uint256 auctionId) 
        external 
        payable 
        auctionExists(auctionId) 
        auctionActive(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        require(msg.sender != auction.seller, "Seller cannot bid on own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        uint256 totalBid = pendingReturns[auctionId][msg.sender] + msg.value;
        
        if (auction.highestBid == 0) {
            require(totalBid >= auction.startingBid, "Bid must be at least the starting bid");
        } else {
            require(totalBid > auction.highestBid, "Bid must be higher than current highest bid");
        }
        
        // Record previous highest bidder for refund
        if (auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] = auction.highestBid;
        }
        
        // Update auction with new highest bid
        auction.highestBid = totalBid;
        auction.highestBidder = payable(msg.sender);
        auction.totalBids++;
        
        // Clear pending returns for new highest bidder
        pendingReturns[auctionId][msg.sender] = 0;
        
        // Record bid
        auctionBids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        // Track bidder's participation
        bool isBidderTracked = false;
        uint256[] storage bidderAuctionsList = bidderAuctions[msg.sender];
        for (uint256 i = 0; i < bidderAuctionsList.length; i++) {
            if (bidderAuctionsList[i] == auctionId) {
                isBidderTracked = true;
                break;
            }
        }
        if (!isBidderTracked) {
            bidderAuctions[msg.sender].push(auctionId);
        }
        
        emit BidPlaced(auctionId, msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev End an auction after the deadline
     * @param auctionId The ID of the auction
     */
    function endAuction(uint256 auctionId) 
        external 
        auctionExists(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        
        auction.status = AuctionStatus.ENDED;
        
        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }
    
    /**
     * @dev Cancel an auction (only before any bids or before end time)
     * @param auctionId The ID of the auction
     */
    function cancelAuction(uint256 auctionId) 
        external 
        auctionExists(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        require(auction.status == AuctionStatus.ACTIVE, "Auction not active");
        require(auction.totalBids == 0, "Cannot cancel auction with bids");
        
        auction.status = AuctionStatus.CANCELLED;
        
        emit AuctionCancelled(auctionId, msg.sender);
    }
    
    /**
     * @dev Withdraw funds for outbid bidders or seller after auction ends
     * @param auctionId The ID of the auction
     */
    function withdraw(uint256 auctionId) external auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        uint256 amount = 0;
        
        // If auction ended and sender is the seller
        if (auction.status == AuctionStatus.ENDED && msg.sender == auction.seller) {
            require(!auction.sellerWithdrawn, "Seller has already withdrawn");
            require(auction.highestBid > 0, "No bids were placed");
            
            amount = auction.highestBid;
            auction.sellerWithdrawn = true;
        } else {
            // For outbid bidders
            amount = pendingReturns[auctionId][msg.sender];
            require(amount > 0, "No funds to withdraw");
            
            pendingReturns[auctionId][msg.sender] = 0;
        }
        
        require(amount > 0, "No funds to withdraw");
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(auctionId, msg.sender, amount);
    }
    
    /**
     * @dev Get auction details
     * @param auctionId The ID of the auction
     * @return id Auction ID
     * @return seller Seller address
     * @return itemName Item name
     * @return description Item description
     * @return startingBid Starting bid amount
     * @return highestBid Current highest bid
     * @return highestBidder Current highest bidder
     * @return startTime Auction start time
     * @return endTime Auction end time
     * @return status Auction status
     * @return totalBids Total number of bids
     */
    function getAuctionDetails(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (
            uint256 id,
            address seller,
            string memory itemName,
            string memory description,
            uint256 startingBid,
            uint256 highestBid,
            address highestBidder,
            uint256 startTime,
            uint256 endTime,
            AuctionStatus status,
            uint256 totalBids
        ) 
    {
        Auction memory auction = auctions[auctionId];
        return (
            auction.id,
            auction.seller,
            auction.itemName,
            auction.description,
            auction.startingBid,
            auction.highestBid,
            auction.highestBidder,
            auction.startTime,
            auction.endTime,
            auction.status,
            auction.totalBids
        );
    }
    
    /**
     * @dev Get all bids for an auction
     * @param auctionId The ID of the auction
     * @return Array of bids
     */
    function getAuctionBids(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (Bid[] memory) 
    {
        return auctionBids[auctionId];
    }
    
    /**
     * @dev Get pending returns for a bidder in an auction
     * @param auctionId The ID of the auction
     * @param bidder The bidder's address
     * @return The amount available to withdraw
     */
    function getPendingReturns(uint256 auctionId, address bidder) 
        external 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        return pendingReturns[auctionId][bidder];
    }
    
    /**
     * @dev Get time remaining for an auction
     * @param auctionId The ID of the auction
     * @return Time remaining in seconds (0 if ended)
     */
    function getTimeRemaining(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        Auction memory auction = auctions[auctionId];
        
        if (block.timestamp >= auction.endTime) {
            return 0;
        }
        
        return auction.endTime - block.timestamp;
    }
    
    /**
     * @dev Check if an auction has ended
     * @param auctionId The ID of the auction
     * @return Whether the auction has ended
     */
    function hasAuctionEnded(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (bool) 
    {
        return block.timestamp >= auctions[auctionId].endTime;
    }
    
    /**
     * @dev Get auctions created by a seller
     * @param seller The seller's address
     * @return Array of auction IDs
     */
    function getAuctionsBySeller(address seller) external view returns (uint256[] memory) {
        return sellerAuctions[seller];
    }
    
    /**
     * @dev Get auctions where a bidder has participated
     * @param bidder The bidder's address
     * @return Array of auction IDs
     */
    function getAuctionsByBidder(address bidder) external view returns (uint256[] memory) {
        return bidderAuctions[bidder];
    }
    
    /**
     * @dev Get active auctions
     * @return Array of active auction IDs
     */
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active auctions
        for (uint256 i = 1; i <= auctionCounter; i++) {
            if (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp < auctions[i].endTime) {
                activeCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeAuctions = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= auctionCounter; i++) {
            if (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp < auctions[i].endTime) {
                activeAuctions[index] = i;
                index++;
            }
        }
        
        return activeAuctions;
    }
    
    /**
     * @dev Get ended auctions
     * @return Array of ended auction IDs
     */
    function getEndedAuctions() external view returns (uint256[] memory) {
        uint256 endedCount = 0;
        
        // Count ended auctions
        for (uint256 i = 1; i <= auctionCounter; i++) {
            if (auctions[i].status == AuctionStatus.ENDED || 
                (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp >= auctions[i].endTime)) {
                endedCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory endedAuctions = new uint256[](endedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= auctionCounter; i++) {
            if (auctions[i].status == AuctionStatus.ENDED || 
                (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp >= auctions[i].endTime)) {
                endedAuctions[index] = i;
                index++;
            }
        }
        
        return endedAuctions;
    }
    
    /**
     * @dev Get the current highest bidder for an auction
     * @param auctionId The ID of the auction
     * @return The address of the highest bidder
     */
    function getHighestBidder(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (address) 
    {
        return auctions[auctionId].highestBidder;
    }
    
    /**
     * @dev Get the current highest bid for an auction
     * @param auctionId The ID of the auction
     * @return The highest bid amount
     */
    function getHighestBid(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        return auctions[auctionId].highestBid;
    }
    
    /**
     * @dev Get total number of auctions
     * @return The total count
     */
    function getTotalAuctions() external view returns (uint256) {
        return auctionCounter;
    }
    
    /**
     * @dev Check if a user is the winner of an auction
     * @param auctionId The ID of the auction
     * @param user The user's address
     * @return Whether the user is the winner
     */
    function isWinner(uint256 auctionId, address user) 
        external 
        view 
        auctionExists(auctionId) 
        returns (bool) 
    {
        Auction memory auction = auctions[auctionId];
        return auction.highestBidder == user && 
               (auction.status == AuctionStatus.ENDED || block.timestamp >= auction.endTime);
    }
}
