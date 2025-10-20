// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeBasedAuction
 * @dev Time-based auction where bids are placed before a deadline and the highest bidder wins
 */
contract TimeBasedAuction {
    // Auction structure
    struct Auction {
        uint256 auctionId;
        address seller;
        string itemName;
        string description;
        uint256 startingBid;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
        bool isFinalized;
        bool exists;
    }

    // Bid structure
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    // State variables
    address public owner;
    uint256 private auctionIdCounter;
    
    // Mappings
    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => Bid[]) private auctionBids;
    mapping(uint256 => mapping(address => uint256)) private pendingReturns;
    mapping(address => uint256[]) private sellerAuctions;
    mapping(address => uint256[]) private bidderAuctions;

    // Events
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        string itemName,
        uint256 startingBid,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime
    );
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId, address indexed seller);
    event BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 indexed auctionId, uint256 newEndTime);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(auctions[auctionId].exists, "Auction does not exist");
        _;
    }

    modifier onlySeller(uint256 auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Not auction seller");
        _;
    }

    modifier auctionActive(uint256 auctionId) {
        require(auctions[auctionId].isActive, "Auction is not active");
        require(block.timestamp >= auctions[auctionId].startTime, "Auction has not started");
        require(block.timestamp <= auctions[auctionId].endTime, "Auction has ended");
        _;
    }

    modifier auctionEnded(uint256 auctionId) {
        require(block.timestamp > auctions[auctionId].endTime, "Auction has not ended");
        _;
    }

    constructor() {
        owner = msg.sender;
        auctionIdCounter = 1;
    }

    /**
     * @dev Create a new auction
     * @param itemName Name of the item
     * @param description Description of the item
     * @param startingBid Starting bid amount
     * @param reservePrice Reserve price (minimum to sell)
     * @param duration Duration in seconds
     * @return auctionId ID of the created auction
     */
    function createAuction(
        string memory itemName,
        string memory description,
        uint256 startingBid,
        uint256 reservePrice,
        uint256 duration
    ) public returns (uint256) {
        require(bytes(itemName).length > 0, "Item name cannot be empty");
        require(startingBid > 0, "Starting bid must be greater than 0");
        require(reservePrice >= startingBid, "Reserve price must be >= starting bid");
        require(duration > 0, "Duration must be greater than 0");

        uint256 auctionId = auctionIdCounter;
        auctionIdCounter++;

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            seller: msg.sender,
            itemName: itemName,
            description: description,
            startingBid: startingBid,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: endTime,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true,
            isFinalized: false,
            exists: true
        });

        sellerAuctions[msg.sender].push(auctionId);

        emit AuctionCreated(auctionId, msg.sender, itemName, startingBid, reservePrice, startTime, endTime);

        return auctionId;
    }

    /**
     * @dev Create auction with specific start time
     * @param itemName Name of the item
     * @param description Description of the item
     * @param startingBid Starting bid amount
     * @param reservePrice Reserve price
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return auctionId ID of the created auction
     */
    function createScheduledAuction(
        string memory itemName,
        string memory description,
        uint256 startingBid,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime
    ) public returns (uint256) {
        require(bytes(itemName).length > 0, "Item name cannot be empty");
        require(startingBid > 0, "Starting bid must be greater than 0");
        require(reservePrice >= startingBid, "Reserve price must be >= starting bid");
        require(startTime >= block.timestamp, "Start time must be in the future");
        require(endTime > startTime, "End time must be after start time");

        uint256 auctionId = auctionIdCounter;
        auctionIdCounter++;

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            seller: msg.sender,
            itemName: itemName,
            description: description,
            startingBid: startingBid,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: endTime,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true,
            isFinalized: false,
            exists: true
        });

        sellerAuctions[msg.sender].push(auctionId);

        emit AuctionCreated(auctionId, msg.sender, itemName, startingBid, reservePrice, startTime, endTime);

        return auctionId;
    }

    /**
     * @dev Place a bid on an auction
     * @param auctionId Auction ID to bid on
     */
    function placeBid(uint256 auctionId) 
        public 
        payable 
        auctionExists(auctionId) 
        auctionActive(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        require(msg.sender != auction.seller, "Seller cannot bid on own auction");
        require(msg.value > 0, "Bid must be greater than 0");

        uint256 totalBid = pendingReturns[auctionId][msg.sender] + msg.value;

        if (auction.highestBid == 0) {
            require(totalBid >= auction.startingBid, "Bid must be at least starting bid");
        } else {
            require(totalBid > auction.highestBid, "Bid must be higher than current highest bid");
        }

        // Track previous highest bidder for return
        if (auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }

        // Update auction state
        auction.highestBidder = msg.sender;
        auction.highestBid = totalBid;
        pendingReturns[auctionId][msg.sender] = 0;

        // Record bid
        auctionBids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: totalBid,
            timestamp: block.timestamp
        }));

        // Track bidder participation
        bool alreadyBid = false;
        uint256[] memory bidderAucs = bidderAuctions[msg.sender];
        for (uint256 i = 0; i < bidderAucs.length; i++) {
            if (bidderAucs[i] == auctionId) {
                alreadyBid = true;
                break;
            }
        }
        if (!alreadyBid) {
            bidderAuctions[msg.sender].push(auctionId);
        }

        emit BidPlaced(auctionId, msg.sender, totalBid, block.timestamp);
    }

    /**
     * @dev Finalize auction after it ends
     * @param auctionId Auction ID to finalize
     */
    function finalizeAuction(uint256 auctionId) 
        public 
        auctionExists(auctionId) 
        auctionEnded(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction already finalized or cancelled");
        require(!auction.isFinalized, "Auction already finalized");

        auction.isActive = false;
        auction.isFinalized = true;

        if (auction.highestBidder != address(0) && auction.highestBid >= auction.reservePrice) {
            // Transfer funds to seller
            payable(auction.seller).transfer(auction.highestBid);
            emit AuctionFinalized(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            // Reserve not met or no bids, return funds to highest bidder if exists
            if (auction.highestBidder != address(0)) {
                pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
            }
            emit AuctionFinalized(auctionId, address(0), 0);
        }
    }

    /**
     * @dev Cancel auction (only before first bid)
     * @param auctionId Auction ID to cancel
     */
    function cancelAuction(uint256 auctionId) 
        public 
        auctionExists(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        require(auction.highestBidder == address(0), "Cannot cancel auction with bids");

        auction.isActive = false;

        emit AuctionCancelled(auctionId, msg.sender);
    }

    /**
     * @dev Withdraw pending returns
     * @param auctionId Auction ID
     */
    function withdraw(uint256 auctionId) public auctionExists(auctionId) {
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit BidWithdrawn(auctionId, msg.sender, amount);
    }

    /**
     * @dev Extend auction end time (only seller, before auction ends)
     * @param auctionId Auction ID
     * @param additionalTime Additional time in seconds
     */
    function extendAuction(uint256 auctionId, uint256 additionalTime) 
        public 
        auctionExists(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp <= auction.endTime, "Auction has already ended");
        require(additionalTime > 0, "Additional time must be greater than 0");

        auction.endTime += additionalTime;

        emit AuctionExtended(auctionId, auction.endTime);
    }

    // View Functions

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
     * @dev Get auction basic info
     * @param auctionId Auction ID
     * @return seller Seller address
     * @return itemName Item name
     * @return highestBid Current highest bid
     * @return highestBidder Current highest bidder
     * @return endTime Auction end time
     * @return isActive Active status
     */
    function getAuctionInfo(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (
            address seller,
            string memory itemName,
            uint256 highestBid,
            address highestBidder,
            uint256 endTime,
            bool isActive
        ) 
    {
        Auction memory auction = auctions[auctionId];
        return (
            auction.seller,
            auction.itemName,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.isActive
        );
    }

    /**
     * @dev Get all bids for an auction
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
     * @dev Get number of bids for an auction
     * @param auctionId Auction ID
     * @return Number of bids
     */
    function getBidCount(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        return auctionBids[auctionId].length;
    }

    /**
     * @dev Get pending returns for a bidder
     * @param auctionId Auction ID
     * @param bidder Bidder address
     * @return Amount pending withdrawal
     */
    function getPendingReturns(uint256 auctionId, address bidder) 
        public 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        return pendingReturns[auctionId][bidder];
    }

    /**
     * @dev Get auctions created by a seller
     * @param seller Seller address
     * @return Array of auction IDs
     */
    function getSellerAuctions(address seller) public view returns (uint256[] memory) {
        return sellerAuctions[seller];
    }

    /**
     * @dev Get auctions a bidder participated in
     * @param bidder Bidder address
     * @return Array of auction IDs
     */
    function getBidderAuctions(address bidder) public view returns (uint256[] memory) {
        return bidderAuctions[bidder];
    }

    /**
     * @dev Get all active auctions
     * @return Array of active auction IDs
     */
    function getActiveAuctions() public view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i < auctionIdCounter; i++) {
            if (auctions[i].exists && auctions[i].isActive && block.timestamp <= auctions[i].endTime) {
                activeCount++;
            }
        }

        uint256[] memory activeAuctions = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i < auctionIdCounter; i++) {
            if (auctions[i].exists && auctions[i].isActive && block.timestamp <= auctions[i].endTime) {
                activeAuctions[index] = i;
                index++;
            }
        }

        return activeAuctions;
    }

    /**
     * @dev Get all ended auctions
     * @return Array of ended auction IDs
     */
    function getEndedAuctions() public view returns (uint256[] memory) {
        uint256 endedCount = 0;
        
        for (uint256 i = 1; i < auctionIdCounter; i++) {
            if (auctions[i].exists && block.timestamp > auctions[i].endTime) {
                endedCount++;
            }
        }

        uint256[] memory endedAuctions = new uint256[](endedCount);
        uint256 index = 0;
        for (uint256 i = 1; i < auctionIdCounter; i++) {
            if (auctions[i].exists && block.timestamp > auctions[i].endTime) {
                endedAuctions[index] = i;
                index++;
            }
        }

        return endedAuctions;
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
        return block.timestamp > auctions[auctionId].endTime;
    }

    /**
     * @dev Check if auction is active
     * @param auctionId Auction ID
     * @return true if active
     */
    function isAuctionActive(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (bool) 
    {
        Auction memory auction = auctions[auctionId];
        return auction.isActive && 
               block.timestamp >= auction.startTime && 
               block.timestamp <= auction.endTime;
    }

    /**
     * @dev Get time remaining for auction
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
     * @dev Get total number of auctions created
     * @return Total auction count
     */
    function getTotalAuctions() public view returns (uint256) {
        return auctionIdCounter - 1;
    }

    /**
     * @dev Check if reserve price was met
     * @param auctionId Auction ID
     * @return true if reserve met
     */
    function isReserveMet(uint256 auctionId) 
        public 
        view 
        auctionExists(auctionId) 
        returns (bool) 
    {
        return auctions[auctionId].highestBid >= auctions[auctionId].reservePrice;
    }
}
