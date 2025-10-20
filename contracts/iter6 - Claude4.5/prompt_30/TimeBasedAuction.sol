// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeBasedAuction
 * @dev A time-based auction where bids are placed before a deadline and the highest bidder wins
 */
contract TimeBasedAuction {
    struct Auction {
        uint256 auctionId;
        address seller;
        string itemName;
        string description;
        uint256 startingPrice;
        uint256 deadline;
        uint256 highestBid;
        address highestBidder;
        bool isActive;
        bool isFinalized;
        uint256 createdAt;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    address public owner;
    uint256 public auctionCount;
    
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;
    
    // Events
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, string itemName, uint256 startingPrice, uint256 deadline);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId, address indexed seller);
    event FundsWithdrawn(uint256 indexed auctionId, address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier auctionExists(uint256 auctionId) {
        require(auctionId > 0 && auctionId <= auctionCount, "Auction does not exist");
        _;
    }
    
    modifier auctionActive(uint256 auctionId) {
        require(auctions[auctionId].isActive, "Auction is not active");
        require(block.timestamp < auctions[auctionId].deadline, "Auction has ended");
        _;
    }
    
    modifier onlySeller(uint256 auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Only seller can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new auction
     * @param itemName Name of the item being auctioned
     * @param description Description of the item
     * @param startingPrice Minimum starting price
     * @param duration Duration in seconds from now
     */
    function createAuction(
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 duration
    ) external returns (uint256) {
        require(bytes(itemName).length > 0, "Item name cannot be empty");
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        auctionCount++;
        uint256 auctionId = auctionCount;
        uint256 deadline = block.timestamp + duration;
        
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            seller: msg.sender,
            itemName: itemName,
            description: description,
            startingPrice: startingPrice,
            deadline: deadline,
            highestBid: 0,
            highestBidder: address(0),
            isActive: true,
            isFinalized: false,
            createdAt: block.timestamp
        });
        
        emit AuctionCreated(auctionId, msg.sender, itemName, startingPrice, deadline);
        
        return auctionId;
    }
    
    /**
     * @dev Place a bid on an auction
     * @param auctionId The auction ID to bid on
     */
    function placeBid(uint256 auctionId) external payable auctionExists(auctionId) auctionActive(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        uint256 totalBid = pendingReturns[auctionId][msg.sender] + msg.value;
        
        // Check if bid is higher than current highest bid or starting price
        if (auction.highestBidder == address(0)) {
            require(totalBid >= auction.startingPrice, "Bid must be at least the starting price");
        } else {
            require(totalBid > auction.highestBid, "Bid must be higher than current highest bid");
        }
        
        // If there was a previous highest bidder (and it's not the current bidder)
        if (auction.highestBidder != address(0) && auction.highestBidder != msg.sender) {
            // Previous highest bidder's funds go to pending returns
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }
        
        // Update auction with new highest bid
        auction.highestBid = totalBid;
        auction.highestBidder = msg.sender;
        
        // Clear the current bidder's pending returns as it's now the highest bid
        pendingReturns[auctionId][msg.sender] = 0;
        
        // Record the bid
        auctionBids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        emit BidPlaced(auctionId, msg.sender, totalBid, block.timestamp);
    }
    
    /**
     * @dev Finalize an auction after the deadline
     * @param auctionId The auction ID to finalize
     */
    function finalizeAuction(uint256 auctionId) external auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(auction.isActive, "Auction is not active");
        require(block.timestamp >= auction.deadline, "Auction has not ended yet");
        require(!auction.isFinalized, "Auction already finalized");
        
        auction.isActive = false;
        auction.isFinalized = true;
        
        if (auction.highestBidder != address(0)) {
            // Transfer funds to seller
            pendingReturns[auctionId][auction.seller] = auction.highestBid;
            
            emit AuctionFinalized(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionFinalized(auctionId, address(0), 0);
        }
    }
    
    /**
     * @dev Cancel an auction (only before any bids are placed)
     * @param auctionId The auction ID to cancel
     */
    function cancelAuction(uint256 auctionId) external auctionExists(auctionId) onlySeller(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(auction.isActive, "Auction is not active");
        require(auction.highestBidder == address(0), "Cannot cancel auction with bids");
        
        auction.isActive = false;
        auction.isFinalized = true;
        
        emit AuctionCancelled(auctionId, msg.sender);
    }
    
    /**
     * @dev Withdraw funds (for outbid bidders and sellers)
     * @param auctionId The auction ID
     */
    function withdraw(uint256 auctionId) external auctionExists(auctionId) {
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingReturns[auctionId][msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(auctionId, msg.sender, amount);
    }
    
    /**
     * @dev Get auction details
     * @param auctionId The auction ID
     * @return seller Seller address
     * @return itemName Item name
     * @return description Item description
     * @return startingPrice Starting price
     * @return deadline Auction deadline
     * @return highestBid Current highest bid
     * @return highestBidder Current highest bidder
     * @return isActive Is auction active
     * @return isFinalized Is auction finalized
     */
    function getAuction(uint256 auctionId) external view auctionExists(auctionId) returns (
        address seller,
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 deadline,
        uint256 highestBid,
        address highestBidder,
        bool isActive,
        bool isFinalized
    ) {
        Auction memory auction = auctions[auctionId];
        
        return (
            auction.seller,
            auction.itemName,
            auction.description,
            auction.startingPrice,
            auction.deadline,
            auction.highestBid,
            auction.highestBidder,
            auction.isActive,
            auction.isFinalized
        );
    }
    
    /**
     * @dev Get all bids for an auction
     * @param auctionId The auction ID
     * @return Array of bids
     */
    function getAuctionBids(uint256 auctionId) external view auctionExists(auctionId) returns (Bid[] memory) {
        return auctionBids[auctionId];
    }
    
    /**
     * @dev Get pending returns for a user in an auction
     * @param auctionId The auction ID
     * @param user The user address
     * @return Pending return amount
     */
    function getPendingReturns(uint256 auctionId, address user) external view auctionExists(auctionId) returns (uint256) {
        return pendingReturns[auctionId][user];
    }
    
    /**
     * @dev Check if auction has ended
     * @param auctionId The auction ID
     * @return True if ended
     */
    function hasAuctionEnded(uint256 auctionId) external view auctionExists(auctionId) returns (bool) {
        return block.timestamp >= auctions[auctionId].deadline;
    }
    
    /**
     * @dev Get time remaining for auction
     * @param auctionId The auction ID
     * @return Time remaining in seconds (0 if ended)
     */
    function getTimeRemaining(uint256 auctionId) external view auctionExists(auctionId) returns (uint256) {
        if (block.timestamp >= auctions[auctionId].deadline) {
            return 0;
        }
        return auctions[auctionId].deadline - block.timestamp;
    }
    
    /**
     * @dev Get all active auctions
     * @return Array of active auction IDs
     */
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count active auctions
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].isActive && block.timestamp < auctions[i].deadline) {
                count++;
            }
        }
        
        // Collect active auction IDs
        uint256[] memory activeAuctions = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].isActive && block.timestamp < auctions[i].deadline) {
                activeAuctions[index] = i;
                index++;
            }
        }
        
        return activeAuctions;
    }
    
    /**
     * @dev Get auctions created by a seller
     * @param seller The seller address
     * @return Array of auction IDs
     */
    function getAuctionsBySeller(address seller) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count auctions by seller
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].seller == seller) {
                count++;
            }
        }
        
        // Collect auction IDs
        uint256[] memory sellerAuctions = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].seller == seller) {
                sellerAuctions[index] = i;
                index++;
            }
        }
        
        return sellerAuctions;
    }
    
    /**
     * @dev Get auctions where user is the highest bidder
     * @param bidder The bidder address
     * @return Array of auction IDs
     */
    function getAuctionsWinning(address bidder) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count auctions where bidder is winning
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].highestBidder == bidder) {
                count++;
            }
        }
        
        // Collect auction IDs
        uint256[] memory winningAuctions = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].highestBidder == bidder) {
                winningAuctions[index] = i;
                index++;
            }
        }
        
        return winningAuctions;
    }
    
    /**
     * @dev Get total number of auctions
     * @return Total auction count
     */
    function getTotalAuctions() external view returns (uint256) {
        return auctionCount;
    }
    
    /**
     * @dev Get number of bids for an auction
     * @param auctionId The auction ID
     * @return Number of bids
     */
    function getBidCount(uint256 auctionId) external view auctionExists(auctionId) returns (uint256) {
        return auctionBids[auctionId].length;
    }
}
