// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    
    enum AuctionStatus { ACTIVE, ENDED, CANCELLED }
    
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
        uint256 bidCount;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;
    
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, string itemName, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId);
    event RefundClaimed(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
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
    ) external {
        require(bytes(_itemName).length > 0, "Item name cannot be empty");
        require(_startingBid > 0, "Starting bid must be greater than zero");
        require(_durationInDays > 0, "Duration must be greater than zero");
        
        auctionCount++;
        
        uint256 endTime = block.timestamp + (_durationInDays * 1 days);
        
        auctions[auctionCount] = Auction({
            id: auctionCount,
            seller: payable(msg.sender),
            itemName: _itemName,
            description: _description,
            startingBid: _startingBid,
            highestBid: 0,
            highestBidder: payable(address(0)),
            startTime: block.timestamp,
            endTime: endTime,
            status: AuctionStatus.ACTIVE,
            bidCount: 0
        });
        
        emit AuctionCreated(auctionCount, msg.sender, _itemName, _startingBid, endTime);
    }
    
    function placeBid(uint256 _auctionId) external payable {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        
        Auction storage auction = auctions[_auctionId];
        
        require(auction.status == AuctionStatus.ACTIVE, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on own auction");
        require(msg.value > 0, "Bid must be greater than zero");
        
        uint256 minBid = auction.highestBid > 0 ? auction.highestBid : auction.startingBid;
        require(msg.value > minBid, "Bid must be higher than current highest bid");
        
        // Return funds to previous highest bidder
        if (auction.highestBidder != address(0)) {
            pendingReturns[_auctionId][auction.highestBidder] += auction.highestBid;
        }
        
        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);
        auction.bidCount++;
        
        auctionBids[_auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }
    
    function endAuction(uint256 _auctionId) external {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        
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
    
    function cancelAuction(uint256 _auctionId) external {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        
        Auction storage auction = auctions[_auctionId];
        
        require(msg.sender == auction.seller, "Only seller can cancel auction");
        require(auction.status == AuctionStatus.ACTIVE, "Auction is not active");
        require(auction.bidCount == 0, "Cannot cancel auction with bids");
        
        auction.status = AuctionStatus.CANCELLED;
        
        emit AuctionCancelled(_auctionId);
    }
    
    function claimRefund(uint256 _auctionId) external {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        
        uint256 amount = pendingReturns[_auctionId][msg.sender];
        require(amount > 0, "No funds to refund");
        
        pendingReturns[_auctionId][msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund transfer failed");
        
        emit RefundClaimed(_auctionId, msg.sender, amount);
    }
    
    function getAuction(uint256 _auctionId) external view returns (
        uint256 id,
        address seller,
        string memory itemName,
        string memory description,
        uint256 startingBid,
        uint256 highestBid,
        address highestBidder,
        uint256 endTime,
        AuctionStatus status,
        uint256 bidCount
    ) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        
        Auction memory auction = auctions[_auctionId];
        
        return (
            auction.id,
            auction.seller,
            auction.itemName,
            auction.description,
            auction.startingBid,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.status,
            auction.bidCount
        );
    }
    
    function getAuctionBids(uint256 _auctionId) external view returns (Bid[] memory) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        return auctionBids[_auctionId];
    }
    
    function getPendingRefund(uint256 _auctionId, address _bidder) external view returns (uint256) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        return pendingReturns[_auctionId][_bidder];
    }
    
    function timeRemaining(uint256 _auctionId) external view returns (uint256) {
        require(_auctionId > 0 && _auctionId <= auctionCount, "Auction does not exist");
        
        Auction memory auction = auctions[_auctionId];
        
        if (block.timestamp >= auction.endTime) {
            return 0;
        }
        
        return auction.endTime - block.timestamp;
    }
    
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp < auctions[i].endTime) {
                activeCount++;
            }
        }
        
        uint256[] memory activeAuctionIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].status == AuctionStatus.ACTIVE && block.timestamp < auctions[i].endTime) {
                activeAuctionIds[index] = i;
                index++;
            }
        }
        
        return activeAuctionIds;
    }
}
