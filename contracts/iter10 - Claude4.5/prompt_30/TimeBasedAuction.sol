// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedAuction {
    address public owner;
    
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
        bool ended;
    }

    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, string itemName, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(auctionId > 0 && auctionId <= auctionCount, "Auction does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createAuction(
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 durationInHours
    ) external returns (uint256) {
        require(bytes(itemName).length > 0, "Item name cannot be empty");
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(durationInHours > 0, "Duration must be greater than 0");

        auctionCount++;
        uint256 endTime = block.timestamp + (durationInHours * 1 hours);

        auctions[auctionCount] = Auction({
            id: auctionCount,
            seller: payable(msg.sender),
            itemName: itemName,
            description: description,
            startingPrice: startingPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            startTime: block.timestamp,
            endTime: endTime,
            active: true,
            ended: false
        });

        emit AuctionCreated(auctionCount, msg.sender, itemName, startingPrice, endTime);

        return auctionCount;
    }

    function placeBid(uint256 auctionId) external payable auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(auction.active, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");
        require(msg.value > 0, "Bid amount must be greater than 0");

        uint256 totalBid = bids[auctionId][msg.sender] + msg.value;

        if (auction.highestBid == 0) {
            require(totalBid >= auction.startingPrice, "Bid must be at least the starting price");
        } else {
            require(totalBid > auction.highestBid, "Bid must be higher than current highest bid");
        }

        bids[auctionId][msg.sender] = totalBid;

        auction.highestBid = totalBid;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(auctionId, msg.sender, totalBid);
    }

    function endAuction(uint256 auctionId) external auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(auction.active, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        require(!auction.ended, "Auction already ended");

        auction.active = false;
        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            // Transfer winning bid to seller
            (bool success, ) = auction.seller.call{value: auction.highestBid}("");
            require(success, "Transfer to seller failed");

            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }

    function withdrawBid(uint256 auctionId) external auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(auction.ended, "Auction has not ended yet");
        require(msg.sender != auction.highestBidder, "Winner cannot withdraw bid");
        
        uint256 bidAmount = bids[auctionId][msg.sender];
        require(bidAmount > 0, "No bid to withdraw");

        bids[auctionId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: bidAmount}("");
        require(success, "Withdrawal failed");

        emit BidWithdrawn(auctionId, msg.sender, bidAmount);
    }

    function cancelAuction(uint256 auctionId) external auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        
        require(msg.sender == auction.seller, "Only seller can cancel auction");
        require(auction.active, "Auction is not active");
        require(auction.highestBidder == address(0), "Cannot cancel auction with bids");

        auction.active = false;
        auction.ended = true;

        emit AuctionEnded(auctionId, address(0), 0);
    }

    function getAuction(uint256 auctionId) external view auctionExists(auctionId) returns (
        uint256 id,
        address seller,
        string memory itemName,
        string memory description,
        uint256 startingPrice,
        uint256 highestBid,
        address highestBidder,
        uint256 endTime,
        bool active,
        bool ended
    ) {
        Auction memory auction = auctions[auctionId];
        return (
            auction.id,
            auction.seller,
            auction.itemName,
            auction.description,
            auction.startingPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.active,
            auction.ended
        );
    }

    function getBidAmount(uint256 auctionId, address bidder) external view auctionExists(auctionId) returns (uint256) {
        return bids[auctionId][bidder];
    }

    function getTimeRemaining(uint256 auctionId) external view auctionExists(auctionId) returns (uint256) {
        Auction memory auction = auctions[auctionId];
        
        if (block.timestamp >= auction.endTime) {
            return 0;
        }
        
        return auction.endTime - block.timestamp;
    }

    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].active && block.timestamp < auctions[i].endTime) {
                activeCount++;
            }
        }

        uint256[] memory activeAuctionIds = new uint256[](activeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].active && block.timestamp < auctions[i].endTime) {
                activeAuctionIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return activeAuctionIds;
    }

    function getEndedAuctions() external view returns (uint256[] memory) {
        uint256 endedCount = 0;
        
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].ended) {
                endedCount++;
            }
        }

        uint256[] memory endedAuctionIds = new uint256[](endedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= auctionCount; i++) {
            if (auctions[i].ended) {
                endedAuctionIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return endedAuctionIds;
    }
}
