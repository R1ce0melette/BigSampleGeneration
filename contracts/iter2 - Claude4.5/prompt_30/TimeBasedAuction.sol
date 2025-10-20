// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    
    enum AuctionStatus { ACTIVE, ENDED, CANCELLED }
    
    struct Auction {
        uint256 auctionId;
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
    }
    
    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(address => uint256[]) public sellerAuctions;
    
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, string itemName, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId);
    event BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier auctionExists(uint256 _auctionId) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Invalid auction ID");
        _;
    }
    
    modifier auctionActive(uint256 _auctionId) {
        require(auctions[_auctionId].status == AuctionStatus.ACTIVE, "Auction is not active");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createAuction(
        string memory _itemName,
        string memory _description,
        uint256 _startingBid,
        uint256 _durationInDays
    ) external returns (uint256) {
        require(bytes(_itemName).length > 0, "Item name cannot be empty");
        require(_startingBid > 0, "Starting bid must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        auctionCount++;
        
        uint256 endTime = block.timestamp + (_durationInDays * 1 days);
        
        auctions[auctionCount] = Auction({
            auctionId: auctionCount,
            seller: payable(msg.sender),
            itemName: _itemName,
            description: _description,
            startingBid: _startingBid,
            highestBid: 0,
            highestBidder: payable(address(0)),
            startTime: block.timestamp,
            endTime: endTime,
            status: AuctionStatus.ACTIVE,
            totalBids: 0
        });
        
        sellerAuctions[msg.sender].push(auctionCount);
        
        emit AuctionCreated(auctionCount, msg.sender, _itemName, _startingBid, endTime);
        
        return auctionCount;
    }
    
    function placeBid(uint256 _auctionId) external payable 
        auctionExists(_auctionId) 
        auctionActive(_auctionId) 
    {
        Auction storage auction = auctions[_auctionId];
        
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        uint256 totalBid = bids[_auctionId][msg.sender] + msg.value;
        
        if (auction.highestBid == 0) {
            require(totalBid >= auction.startingBid, "Bid must be at least the starting bid");
        } else {
            require(totalBid > auction.highestBid, "Bid must be higher than current highest bid");
        }
        
        bids[_auctionId][msg.sender] = totalBid;
        auction.highestBid = totalBid;
        auction.highestBidder = payable(msg.sender);
        auction.totalBids++;
        
        emit BidPlaced(_auctionId, msg.sender, totalBid, block.timestamp);
    }
    
    function endAuction(uint256 _auctionId) external auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.status == AuctionStatus.ACTIVE, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        
        auction.status = AuctionStatus.ENDED;
        
        if (auction.highestBidder != address(0)) {
            // Transfer winning bid to seller
            (bool success, ) = auction.seller.call{value: auction.highestBid}("");
            require(success, "Transfer to seller failed");
            
            emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionEnded(_auctionId, address(0), 0);
        }
    }
    
    function cancelAuction(uint256 _auctionId) external auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(msg.sender == auction.seller, "Only seller can cancel auction");
        require(auction.status == AuctionStatus.ACTIVE, "Auction is not active");
        require(auction.highestBid == 0, "Cannot cancel auction with bids");
        
        auction.status = AuctionStatus.CANCELLED;
        
        emit AuctionCancelled(_auctionId);
    }
    
    function withdrawBid(uint256 _auctionId) external auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        
        require(auction.status == AuctionStatus.ENDED, "Auction must be ended");
        require(msg.sender != auction.highestBidder, "Winner cannot withdraw");
        
        uint256 bidAmount = bids[_auctionId][msg.sender];
        require(bidAmount > 0, "No bid to withdraw");
        
        bids[_auctionId][msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: bidAmount}("");
        require(success, "Withdrawal failed");
        
        emit BidWithdrawn(_auctionId, msg.sender, bidAmount);
    }
    
    function getAuction(uint256 _auctionId) external view auctionExists(_auctionId) returns (
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
    ) {
        Auction memory auction = auctions[_auctionId];
        
        return (
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
    
    function getUserBid(uint256 _auctionId, address _bidder) external view auctionExists(_auctionId) returns (uint256) {
        return bids[_auctionId][_bidder];
    }
    
    function getSellerAuctions(address _seller) external view returns (uint256[] memory) {
        return sellerAuctions[_seller];
    }
    
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp < auctions[i].endTime) {
                activeCount++;
            }
        }
        
        uint256[] memory activeAuctions = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp < auctions[i].endTime) {
                activeAuctions[index] = i;
                index++;
            }
        }
        
        return activeAuctions;
    }
    
    function getTimeRemaining(uint256 _auctionId) external view auctionExists(_auctionId) returns (uint256) {
        Auction memory auction = auctions[_auctionId];
        
        if (block.timestamp >= auction.endTime) {
            return 0;
        }
        
        return auction.endTime - block.timestamp;
    }
    
    function isAuctionEnded(uint256 _auctionId) external view auctionExists(_auctionId) returns (bool) {
        return block.timestamp >= auctions[_auctionId].endTime;
    }
}
