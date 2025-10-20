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
        uint256 highestBid;
        address highestBidder;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isFinalized;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    address public owner;
    uint256 public totalAuctions;
    uint256 public platformFeePercentage; // Fee in basis points (e.g., 250 = 2.5%)
    
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => uint256[]) public userBids;
    
    // Events
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, string itemName, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId, address indexed seller);
    event FundsWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier auctionExists(uint256 _auctionId) {
        require(auctions[_auctionId].auctionId != 0, "Auction does not exist");
        _;
    }
    
    modifier onlySeller(uint256 _auctionId) {
        require(auctions[_auctionId].seller == msg.sender, "Only seller can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     * @param _platformFeePercentage The platform fee in basis points (250 = 2.5%)
     */
    constructor(uint256 _platformFeePercentage) {
        owner = msg.sender;
        platformFeePercentage = _platformFeePercentage;
    }
    
    /**
     * @dev Creates a new auction
     * @param _itemName The name of the item being auctioned
     * @param _description Description of the item
     * @param _startingPrice The starting price for the auction
     * @param _duration Duration of the auction in seconds
     */
    function createAuction(
        string memory _itemName,
        string memory _description,
        uint256 _startingPrice,
        uint256 _duration
    ) external returns (uint256) {
        require(bytes(_itemName).length > 0, "Item name cannot be empty");
        require(_startingPrice > 0, "Starting price must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        
        totalAuctions++;
        uint256 auctionId = totalAuctions;
        
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            seller: msg.sender,
            itemName: _itemName,
            description: _description,
            startingPrice: _startingPrice,
            highestBid: 0,
            highestBidder: address(0),
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            isActive: true,
            isFinalized: false
        });
        
        userAuctions[msg.sender].push(auctionId);
        
        emit AuctionCreated(auctionId, msg.sender, _itemName, _startingPrice, auctions[auctionId].endTime);
        
        return auctionId;
    }
    
    /**
     * @dev Places a bid on an auction
     * @param _auctionId The ID of the auction
     */
    function placeBid(uint256 _auctionId) external payable auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.isActive, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        if (auction.highestBid == 0) {
            require(msg.value >= auction.startingPrice, "Bid must be at least the starting price");
        } else {
            require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");
        }
        
        // If there was a previous highest bidder, add their bid to pending returns
        if (auction.highestBidder != address(0)) {
            pendingReturns[_auctionId][auction.highestBidder] += auction.highestBid;
        }
        
        // Update highest bid
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        
        // Record the bid
        auctionBids[_auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        // Track user's bid
        bool alreadyBid = false;
        for (uint256 i = 0; i < userBids[msg.sender].length; i++) {
            if (userBids[msg.sender][i] == _auctionId) {
                alreadyBid = true;
                break;
            }
        }
        if (!alreadyBid) {
            userBids[msg.sender].push(_auctionId);
        }
        
        emit BidPlaced(_auctionId, msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Finalizes an auction after the deadline
     * @param _auctionId The ID of the auction
     */
    function finalizeAuction(uint256 _auctionId) external auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.isActive, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        require(!auction.isFinalized, "Auction already finalized");
        
        auction.isActive = false;
        auction.isFinalized = true;
        
        if (auction.highestBidder != address(0)) {
            // Calculate platform fee
            uint256 platformFee = (auction.highestBid * platformFeePercentage) / 10000;
            uint256 sellerAmount = auction.highestBid - platformFee;
            
            // Transfer funds to seller
            payable(auction.seller).transfer(sellerAmount);
            
            // Transfer platform fee to owner
            if (platformFee > 0) {
                payable(owner).transfer(platformFee);
            }
            
            emit AuctionFinalized(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionFinalized(_auctionId, address(0), 0);
        }
    }
    
    /**
     * @dev Withdraws funds for a non-winning bidder
     * @param _auctionId The ID of the auction
     */
    function withdrawBid(uint256 _auctionId) external auctionExists(_auctionId) {
        uint256 amount = pendingReturns[_auctionId][msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingReturns[_auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        
        emit FundsWithdrawn(_auctionId, msg.sender, amount);
    }
    
    /**
     * @dev Cancels an auction (only if no bids have been placed)
     * @param _auctionId The ID of the auction
     */
    function cancelAuction(uint256 _auctionId) external auctionExists(_auctionId) onlySeller(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.isActive, "Auction is not active");
        require(auction.highestBidder == address(0), "Cannot cancel auction with bids");
        
        auction.isActive = false;
        
        emit AuctionCancelled(_auctionId, msg.sender);
    }
    
    /**
     * @dev Extends the auction deadline (only seller, before auction ends)
     * @param _auctionId The ID of the auction
     * @param _additionalTime Additional time in seconds
     */
    function extendAuction(uint256 _auctionId, uint256 _additionalTime) external auctionExists(_auctionId) onlySeller(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.isActive, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has already ended");
        require(_additionalTime > 0, "Additional time must be greater than 0");
        
        auction.endTime += _additionalTime;
    }
    
    /**
     * @dev Returns auction details
     * @param _auctionId The ID of the auction
     * @return auctionId The auction ID
     * @return seller The seller's address
     * @return itemName The item name
     * @return description The description
     * @return startingPrice The starting price
     * @return highestBid The highest bid amount
     * @return highestBidder The highest bidder's address
     * @return startTime The start time
     * @return endTime The end time
     * @return isActive Whether the auction is active
     * @return isFinalized Whether the auction is finalized
     */
    function getAuction(uint256 _auctionId) external view auctionExists(_auctionId) returns (
        uint256 auctionId,
        address seller,
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 highestBid,
        address highestBidder,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool isFinalized
    ) {
        Auction memory auction = auctions[_auctionId];
        
        return (
            auction.auctionId,
            auction.seller,
            auction.itemName,
            auction.description,
            auction.startingPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.startTime,
            auction.endTime,
            auction.isActive,
            auction.isFinalized
        );
    }
    
    /**
     * @dev Returns all bids for an auction
     * @param _auctionId The ID of the auction
     * @return Array of bids
     */
    function getAuctionBids(uint256 _auctionId) external view auctionExists(_auctionId) returns (Bid[] memory) {
        return auctionBids[_auctionId];
    }
    
    /**
     * @dev Returns the pending return amount for a bidder
     * @param _auctionId The ID of the auction
     * @param _bidder The address of the bidder
     * @return The pending return amount
     */
    function getPendingReturn(uint256 _auctionId, address _bidder) external view returns (uint256) {
        return pendingReturns[_auctionId][_bidder];
    }
    
    /**
     * @dev Returns all auctions created by a user
     * @param _user The address of the user
     * @return Array of auction IDs
     */
    function getUserAuctions(address _user) external view returns (uint256[] memory) {
        return userAuctions[_user];
    }
    
    /**
     * @dev Returns all auctions a user has bid on
     * @param _user The address of the user
     * @return Array of auction IDs
     */
    function getUserBids(address _user) external view returns (uint256[] memory) {
        return userBids[_user];
    }
    
    /**
     * @dev Returns all active auctions
     * @return Array of auction IDs
     */
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count active auctions
        for (uint256 i = 1; i <= totalAuctions; i++) {
            if (auctions[i].isActive) {
                count++;
            }
        }
        
        // Create array of active auction IDs
        uint256[] memory activeAuctions = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalAuctions; i++) {
            if (auctions[i].isActive) {
                activeAuctions[index] = i;
                index++;
            }
        }
        
        return activeAuctions;
    }
    
    /**
     * @dev Returns all ended but not finalized auctions
     * @return Array of auction IDs
     */
    function getEndedAuctions() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalAuctions; i++) {
            if (auctions[i].isActive && block.timestamp >= auctions[i].endTime && !auctions[i].isFinalized) {
                count++;
            }
        }
        
        uint256[] memory endedAuctions = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalAuctions; i++) {
            if (auctions[i].isActive && block.timestamp >= auctions[i].endTime && !auctions[i].isFinalized) {
                endedAuctions[index] = i;
                index++;
            }
        }
        
        return endedAuctions;
    }
    
    /**
     * @dev Checks if an auction has ended
     * @param _auctionId The ID of the auction
     * @return True if ended, false otherwise
     */
    function hasAuctionEnded(uint256 _auctionId) external view auctionExists(_auctionId) returns (bool) {
        return block.timestamp >= auctions[_auctionId].endTime;
    }
    
    /**
     * @dev Returns the time remaining for an auction
     * @param _auctionId The ID of the auction
     * @return Time remaining in seconds (0 if ended)
     */
    function getTimeRemaining(uint256 _auctionId) external view auctionExists(_auctionId) returns (uint256) {
        if (block.timestamp >= auctions[_auctionId].endTime) {
            return 0;
        }
        
        return auctions[_auctionId].endTime - block.timestamp;
    }
    
    /**
     * @dev Returns the total number of auctions
     * @return Total number of auctions
     */
    function getTotalAuctions() external view returns (uint256) {
        return totalAuctions;
    }
    
    /**
     * @dev Returns the number of bids for an auction
     * @param _auctionId The ID of the auction
     * @return Number of bids
     */
    function getBidCount(uint256 _auctionId) external view auctionExists(_auctionId) returns (uint256) {
        return auctionBids[_auctionId].length;
    }
    
    /**
     * @dev Updates the platform fee percentage (only owner)
     * @param _newFeePercentage The new fee percentage in basis points
     */
    function updatePlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 1000, "Fee cannot exceed 10%");
        platformFeePercentage = _newFeePercentage;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
