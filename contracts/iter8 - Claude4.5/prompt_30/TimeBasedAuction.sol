// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeBasedAuction
 * @dev Contract for a time-based auction where bids are placed before a deadline and the highest bidder wins
 */
contract TimeBasedAuction {
    // Auction status enum
    enum AuctionStatus {
        Active,
        Ended,
        Cancelled
    }

    // Auction structure
    struct Auction {
        uint256 id;
        address seller;
        string itemName;
        string description;
        uint256 startingPrice;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        uint256 totalBids;
        AuctionStatus status;
        bool fundsWithdrawn;
        uint256 createdAt;
    }

    // Bid structure
    struct Bid {
        uint256 id;
        uint256 auctionId;
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    // Bidder statistics
    struct BidderStats {
        uint256 totalBids;
        uint256 totalAuctionsWon;
        uint256 totalAmountSpent;
        uint256 totalAmountBid;
    }

    // Seller statistics
    struct SellerStats {
        uint256 auctionsCreated;
        uint256 auctionsCompleted;
        uint256 totalRevenue;
    }

    // State variables
    address public owner;
    uint256 private auctionCounter;
    uint256 private bidCounter;
    uint256 public platformFeePercentage; // in basis points (100 = 1%)

    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => Bid[]) private auctionBids;
    mapping(uint256 => mapping(address => uint256)) private bidderAmounts;
    mapping(address => uint256[]) private sellerAuctions;
    mapping(address => uint256[]) private bidderAuctions;
    mapping(address => BidderStats) private bidderStats;
    mapping(address => SellerStats) private sellerStats;
    mapping(address => uint256) private pendingReturns;

    uint256[] private allAuctionIds;

    // Events
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, string itemName, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId, address indexed seller);
    event FundsWithdrawn(uint256 indexed auctionId, address indexed seller, uint256 amount);
    event BidRefunded(address indexed bidder, uint256 amount);
    event PlatformFeeUpdated(uint256 newFeePercentage);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(auctionId > 0 && auctionId <= auctionCounter, "Auction does not exist");
        _;
    }

    modifier onlySeller(uint256 auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Not the seller");
        _;
    }

    modifier auctionActive(uint256 auctionId) {
        require(auctions[auctionId].status == AuctionStatus.Active, "Auction is not active");
        require(block.timestamp < auctions[auctionId].endTime, "Auction has ended");
        _;
    }

    modifier auctionEnded(uint256 auctionId) {
        require(
            block.timestamp >= auctions[auctionId].endTime || 
            auctions[auctionId].status == AuctionStatus.Ended,
            "Auction has not ended yet"
        );
        _;
    }

    constructor(uint256 _platformFeePercentage) {
        owner = msg.sender;
        auctionCounter = 0;
        bidCounter = 0;
        platformFeePercentage = _platformFeePercentage;
    }

    /**
     * @dev Create a new auction
     * @param itemName Name of the item
     * @param description Description of the item
     * @param startingPrice Starting price
     * @param reservePrice Reserve price (minimum acceptable price)
     * @param duration Duration in seconds
     * @return auctionId ID of the created auction
     */
    function createAuction(
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 duration
    ) public returns (uint256) {
        require(bytes(itemName).length > 0, "Item name cannot be empty");
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(reservePrice >= startingPrice, "Reserve price must be >= starting price");
        require(duration > 0, "Duration must be greater than 0");

        auctionCounter++;
        uint256 auctionId = auctionCounter;

        uint256 endTime = block.timestamp + duration;

        Auction storage newAuction = auctions[auctionId];
        newAuction.id = auctionId;
        newAuction.seller = msg.sender;
        newAuction.itemName = itemName;
        newAuction.description = description;
        newAuction.startingPrice = startingPrice;
        newAuction.reservePrice = reservePrice;
        newAuction.startTime = block.timestamp;
        newAuction.endTime = endTime;
        newAuction.highestBidder = address(0);
        newAuction.highestBid = 0;
        newAuction.totalBids = 0;
        newAuction.status = AuctionStatus.Active;
        newAuction.fundsWithdrawn = false;
        newAuction.createdAt = block.timestamp;

        sellerAuctions[msg.sender].push(auctionId);
        allAuctionIds.push(auctionId);

        // Update statistics
        sellerStats[msg.sender].auctionsCreated++;

        emit AuctionCreated(auctionId, msg.sender, itemName, startingPrice, endTime);

        return auctionId;
    }

    /**
     * @dev Place a bid on an auction
     * @param auctionId Auction ID
     */
    function placeBid(uint256 auctionId) 
        public 
        payable 
        auctionExists(auctionId) 
        auctionActive(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        uint256 totalBidAmount = bidderAmounts[auctionId][msg.sender] + msg.value;
        
        require(
            totalBidAmount > auction.highestBid,
            "Bid must be higher than current highest bid"
        );
        
        require(
            totalBidAmount >= auction.startingPrice,
            "Bid must be at least the starting price"
        );

        // Record the bid
        bidCounter++;
        Bid memory newBid = Bid({
            id: bidCounter,
            auctionId: auctionId,
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        auctionBids[auctionId].push(newBid);

        // Update bidder's total amount for this auction
        bidderAmounts[auctionId][msg.sender] = totalBidAmount;

        // Update highest bid if this is the new highest
        if (totalBidAmount > auction.highestBid) {
            // Return funds to previous highest bidder
            if (auction.highestBidder != address(0)) {
                pendingReturns[auction.highestBidder] += auction.highestBid;
            }

            auction.highestBidder = msg.sender;
            auction.highestBid = totalBidAmount;
        } else {
            // If not the highest, add to pending returns
            pendingReturns[msg.sender] += msg.value;
        }

        auction.totalBids++;

        // Track bidder participation
        if (bidderStats[msg.sender].totalBids == 0) {
            bidderAuctions[msg.sender].push(auctionId);
        }

        // Update statistics
        bidderStats[msg.sender].totalBids++;
        bidderStats[msg.sender].totalAmountBid += msg.value;

        emit BidPlaced(auctionId, msg.sender, totalBidAmount, block.timestamp);
    }

    /**
     * @dev End an auction
     * @param auctionId Auction ID
     */
    function endAuction(uint256 auctionId) 
        public 
        auctionExists(auctionId) 
        auctionEnded(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Active, "Auction already ended or cancelled");

        auction.status = AuctionStatus.Ended;

        // Update seller statistics
        if (auction.highestBidder != address(0) && auction.highestBid >= auction.reservePrice) {
            sellerStats[auction.seller].auctionsCompleted++;
            sellerStats[auction.seller].totalRevenue += auction.highestBid;
            
            // Update bidder statistics
            bidderStats[auction.highestBidder].totalAuctionsWon++;
            bidderStats[auction.highestBidder].totalAmountSpent += auction.highestBid;
        }

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    /**
     * @dev Cancel an auction (only if no bids have been placed)
     * @param auctionId Auction ID
     */
    function cancelAuction(uint256 auctionId) 
        public 
        auctionExists(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Active, "Auction is not active");
        require(auction.totalBids == 0, "Cannot cancel auction with bids");

        auction.status = AuctionStatus.Cancelled;

        emit AuctionCancelled(auctionId, msg.sender);
    }

    /**
     * @dev Withdraw funds after auction ends
     * @param auctionId Auction ID
     */
    function withdrawFunds(uint256 auctionId) 
        public 
        auctionExists(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Ended, "Auction has not ended");
        require(!auction.fundsWithdrawn, "Funds already withdrawn");
        require(auction.highestBid >= auction.reservePrice, "Reserve price not met");
        require(auction.highestBidder != address(0), "No bids placed");

        auction.fundsWithdrawn = true;

        uint256 platformFee = (auction.highestBid * platformFeePercentage) / 10000;
        uint256 sellerAmount = auction.highestBid - platformFee;

        // Transfer to seller
        payable(auction.seller).transfer(sellerAmount);

        // Transfer platform fee to owner
        if (platformFee > 0) {
            payable(owner).transfer(platformFee);
        }

        emit FundsWithdrawn(auctionId, auction.seller, sellerAmount);
    }

    /**
     * @dev Withdraw pending returns (for outbid bidders)
     */
    function withdrawPendingReturns() public {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No pending returns");

        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit BidRefunded(msg.sender, amount);
    }

    /**
     * @dev Withdraw bid if reserve price not met
     * @param auctionId Auction ID
     */
    function withdrawUnsuccessfulBid(uint256 auctionId) 
        public 
        auctionExists(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Ended, "Auction has not ended");
        require(
            auction.highestBid < auction.reservePrice || auction.highestBidder == address(0),
            "Auction was successful"
        );

        uint256 bidAmount = bidderAmounts[auctionId][msg.sender];
        require(bidAmount > 0, "No bid to withdraw");

        bidderAmounts[auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(bidAmount);

        emit BidRefunded(msg.sender, bidAmount);
    }

    /**
     * @dev Get auction details
     * @param auctionId Auction ID
     * @return Auction details
     */
    function getAuction(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (Auction memory) 
    {
        return auctions[auctionId];
    }

    /**
     * @dev Get auction bids
     * @param auctionId Auction ID
     * @return Array of bids
     */
    function getAuctionBids(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (Bid[] memory) 
    {
        return auctionBids[auctionId];
    }

    /**
     * @dev Get bidder's total bid amount for an auction
     * @param auctionId Auction ID
     * @param bidder Bidder address
     * @return Total bid amount
     */
    function getBidderAmount(uint256 auctionId, address bidder) 
        public 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        return bidderAmounts[auctionId][bidder];
    }

    /**
     * @dev Get pending returns for a bidder
     * @param bidder Bidder address
     * @return Pending return amount
     */
    function getPendingReturns(address bidder) public view returns (uint256) {
        return pendingReturns[bidder];
    }

    /**
     * @dev Get seller auctions
     * @param seller Seller address
     * @return Array of auction IDs
     */
    function getSellerAuctions(address seller) public view returns (uint256[] memory) {
        return sellerAuctions[seller];
    }

    /**
     * @dev Get bidder auctions
     * @param bidder Bidder address
     * @return Array of auction IDs
     */
    function getBidderAuctions(address bidder) public view returns (uint256[] memory) {
        return bidderAuctions[bidder];
    }

    /**
     * @dev Get all auctions
     * @return Array of all auctions
     */
    function getAllAuctions() public view returns (Auction[] memory) {
        Auction[] memory allAuctions = new Auction[](allAuctionIds.length);
        
        for (uint256 i = 0; i < allAuctionIds.length; i++) {
            allAuctions[i] = auctions[allAuctionIds[i]];
        }
        
        return allAuctions;
    }

    /**
     * @dev Get active auctions
     * @return Array of active auctions
     */
    function getActiveAuctions() public view returns (Auction[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allAuctionIds.length; i++) {
            Auction memory auction = auctions[allAuctionIds[i]];
            if (auction.status == AuctionStatus.Active && block.timestamp < auction.endTime) {
                count++;
            }
        }

        Auction[] memory result = new Auction[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allAuctionIds.length; i++) {
            Auction memory auction = auctions[allAuctionIds[i]];
            if (auction.status == AuctionStatus.Active && block.timestamp < auction.endTime) {
                result[index] = auction;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get ended auctions
     * @return Array of ended auctions
     */
    function getEndedAuctions() public view returns (Auction[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allAuctionIds.length; i++) {
            Auction memory auction = auctions[allAuctionIds[i]];
            if (auction.status == AuctionStatus.Ended || 
                (auction.status == AuctionStatus.Active && block.timestamp >= auction.endTime)) {
                count++;
            }
        }

        Auction[] memory result = new Auction[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allAuctionIds.length; i++) {
            Auction memory auction = auctions[allAuctionIds[i]];
            if (auction.status == AuctionStatus.Ended || 
                (auction.status == AuctionStatus.Active && block.timestamp >= auction.endTime)) {
                result[index] = auction;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Check if auction has ended
     * @param auctionId Auction ID
     * @return true if ended
     */
    function hasAuctionEnded(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (bool) 
    {
        return block.timestamp >= auctions[auctionId].endTime;
    }

    /**
     * @dev Get time remaining in auction
     * @param auctionId Auction ID
     * @return Seconds remaining (0 if ended)
     */
    function getTimeRemaining(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        if (block.timestamp >= auctions[auctionId].endTime) {
            return 0;
        }
        return auctions[auctionId].endTime - block.timestamp;
    }

    /**
     * @dev Check if reserve price is met
     * @param auctionId Auction ID
     * @return true if met
     */
    function isReservePriceMet(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (bool) 
    {
        return auctions[auctionId].highestBid >= auctions[auctionId].reservePrice;
    }

    /**
     * @dev Get bidder statistics
     * @param bidder Bidder address
     * @return BidderStats details
     */
    function getBidderStats(address bidder) public view returns (BidderStats memory) {
        return bidderStats[bidder];
    }

    /**
     * @dev Get seller statistics
     * @param seller Seller address
     * @return SellerStats details
     */
    function getSellerStats(address seller) public view returns (SellerStats memory) {
        return sellerStats[seller];
    }

    /**
     * @dev Get total auction count
     * @return Total number of auctions
     */
    function getTotalAuctionCount() public view returns (uint256) {
        return auctionCounter;
    }

    /**
     * @dev Get total bid count
     * @return Total number of bids
     */
    function getTotalBidCount() public view returns (uint256) {
        return bidCounter;
    }

    /**
     * @dev Update platform fee percentage
     * @param newFeePercentage New fee percentage in basis points
     */
    function updatePlatformFee(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 1000, "Fee cannot exceed 10%");
        platformFeePercentage = newFeePercentage;

        emit PlatformFeeUpdated(newFeePercentage);
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
