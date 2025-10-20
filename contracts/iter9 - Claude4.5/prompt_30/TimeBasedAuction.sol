// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    struct Auction {
        uint256 id;
        address payable seller;
        string itemName;
        string description;
        uint256 startingPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool finalized;
    }
    
    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;
    
    // Events
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        string itemName,
        uint256 startingPrice,
        uint256 endTime
    );
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 amount);
    event AuctionCancelled(uint256 indexed auctionId);
    event BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    
    /**
     * @dev Create a new auction
     * @param _itemName The name of the item
     * @param _description The description of the item
     * @param _startingPrice The starting price
     * @param _duration The auction duration in seconds
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
        
        auctionCount++;
        uint256 auctionId = auctionCount;
        
        auctions[auctionId] = Auction({
            id: auctionId,
            seller: payable(msg.sender),
            itemName: _itemName,
            description: _description,
            startingPrice: _startingPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            active: true,
            finalized: false
        });
        
        emit AuctionCreated(auctionId, msg.sender, _itemName, _startingPrice, auctions[auctionId].endTime);
        
        return auctionId;
    }
    
    /**
     * @dev Place a bid on an auction
     * @param _auctionId The ID of the auction
     */
    function placeBid(uint256 _auctionId) external payable {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        Auction storage auction = auctions[_auctionId];
        
        require(auction.active, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        uint256 totalBid = bids[_auctionId][msg.sender] + msg.value;
        
        if (auction.highestBid == 0) {
            require(totalBid >= auction.startingPrice, "Bid is below starting price");
        } else {
            require(totalBid > auction.highestBid, "Bid is not higher than current highest bid");
        }
        
        bids[_auctionId][msg.sender] = totalBid;
        auction.highestBid = totalBid;
        auction.highestBidder = payable(msg.sender);
        
        emit BidPlaced(_auctionId, msg.sender, totalBid);
    }
    
    /**
     * @dev Finalize an auction and transfer funds
     * @param _auctionId The ID of the auction
     */
    function finalizeAuction(uint256 _auctionId) external {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        Auction storage auction = auctions[_auctionId];
        
        require(auction.active, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        require(!auction.finalized, "Auction already finalized");
        
        auction.active = false;
        auction.finalized = true;
        
        if (auction.highestBidder != address(0)) {
            // Transfer winning bid to seller
            (bool success, ) = auction.seller.call{value: auction.highestBid}("");
            require(success, "Transfer to seller failed");
            
            emit AuctionFinalized(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionCancelled(_auctionId);
        }
    }
    
    /**
     * @dev Withdraw a non-winning bid
     * @param _auctionId The ID of the auction
     */
    function withdrawBid(uint256 _auctionId) external {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        Auction storage auction = auctions[_auctionId];
        
        require(auction.finalized, "Auction not finalized yet");
        require(msg.sender != auction.highestBidder, "Winner cannot withdraw");
        
        uint256 amount = bids[_auctionId][msg.sender];
        require(amount > 0, "No bid to withdraw");
        
        bids[_auctionId][msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit BidWithdrawn(_auctionId, msg.sender, amount);
    }
    
    /**
     * @dev Cancel an auction (only seller, only if no bids)
     * @param _auctionId The ID of the auction
     */
    function cancelAuction(uint256 _auctionId) external {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        Auction storage auction = auctions[_auctionId];
        
        require(msg.sender == auction.seller, "Only seller can cancel");
        require(auction.active, "Auction is not active");
        require(auction.highestBidder == address(0), "Cannot cancel with existing bids");
        
        auction.active = false;
        auction.finalized = true;
        
        emit AuctionCancelled(_auctionId);
    }
    
    /**
     * @dev Get auction details
     * @param _auctionId The ID of the auction
     * @return All auction details
     */
    function getAuction(uint256 _auctionId) external view returns (
        uint256 id,
        address seller,
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 highestBid,
        address highestBidder,
        uint256 startTime,
        uint256 endTime,
        bool active,
        bool finalized
    ) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        Auction memory auction = auctions[_auctionId];
        
        return (
            auction.id,
            auction.seller,
            auction.itemName,
            auction.description,
            auction.startingPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.startTime,
            auction.endTime,
            auction.active,
            auction.finalized
        );
    }
    
    /**
     * @dev Get bid amount for a user in an auction
     * @param _auctionId The ID of the auction
     * @param _bidder The bidder address
     * @return The bid amount
     */
    function getBid(uint256 _auctionId, address _bidder) external view returns (uint256) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        return bids[_auctionId][_bidder];
    }
    
    /**
     * @dev Check if auction has ended
     * @param _auctionId The ID of the auction
     * @return True if ended, false otherwise
     */
    function hasEnded(uint256 _auctionId) external view returns (bool) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        return block.timestamp >= auctions[_auctionId].endTime;
    }
    
    /**
     * @dev Get time remaining for an auction
     * @param _auctionId The ID of the auction
     * @return Time remaining in seconds (0 if ended)
     */
    function getTimeRemaining(uint256 _auctionId) external view returns (uint256) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        Auction memory auction = auctions[_auctionId];
        
        if (block.timestamp >= auction.endTime) {
            return 0;
        }
        
        return auction.endTime - block.timestamp;
    }
    
    /**
     * @dev Get active auctions (up to a limit)
     * @param _limit Maximum number of auctions to return
     * @return Array of active auction IDs
     */
    function getActiveAuctions(uint256 _limit) external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active auctions
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].active && block.timestamp < auctions[i].endTime) {
                activeCount++;
            }
        }
        
        uint256 size = activeCount < _limit ? activeCount : _limit;
        uint256[] memory activeAuctions = new uint256[](size);
        
        uint256 index = 0;
        for (uint256 i = auctionCount; i >= 1 && index < size; i--) {
            if (auctions[i].active && block.timestamp < auctions[i].endTime) {
                activeAuctions[index] = i;
                index++;
            }
        }
        
        return activeAuctions;
    }
    
    /**
     * @dev Get ended but not finalized auctions
     * @param _limit Maximum number of auctions to return
     * @return Array of auction IDs
     */
    function getPendingFinalization(uint256 _limit) external view returns (uint256[] memory) {
        uint256 pendingCount = 0;
        
        // Count pending auctions
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].active && 
                !auctions[i].finalized && 
                block.timestamp >= auctions[i].endTime) {
                pendingCount++;
            }
        }
        
        uint256 size = pendingCount < _limit ? pendingCount : _limit;
        uint256[] memory pendingAuctions = new uint256[](size);
        
        uint256 index = 0;
        for (uint256 i = 1; i <= auctionCount && index < size; i++) {
            if (auctions[i].active && 
                !auctions[i].finalized && 
                block.timestamp >= auctions[i].endTime) {
                pendingAuctions[index] = i;
                index++;
            }
        }
        
        return pendingAuctions;
    }
    
    /**
     * @dev Check if a user is winning an auction
     * @param _auctionId The ID of the auction
     * @param _user The user address
     * @return True if winning, false otherwise
     */
    function isWinning(uint256 _auctionId, address _user) external view returns (bool) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        
        return auctions[_auctionId].highestBidder == _user;
    }
}
