// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/DutchAuction.sol";
import "../src/MockNFT.sol";

/**
 * @title DutchAuctionEdgeCasesTest
 * @dev Additional tests for edge cases and advanced scenarios
 */
contract DutchAuctionEdgeCasesTest is Test {
    DutchAuction public auction;
    MockNFT public nft;
    
    address public seller = address(0x1);
    address public buyer1 = address(0x2);
    address public buyer2 = address(0x3);
    
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant STARTING_PRICE = 10 ether;
    uint256 public constant RESERVE_PRICE = 1 ether;
    uint256 public constant DURATION = 3600; // 1 hour
    
    function setUp() public {
        vm.prank(seller);
        nft = new MockNFT();
        
        vm.prank(seller);
        nft.mintWithId(seller, TOKEN_ID);
        
        vm.prank(seller);
        auction = new DutchAuction(
            address(nft),
            TOKEN_ID,
            STARTING_PRICE,
            RESERVE_PRICE,
            DURATION
        );
        
        vm.prank(seller);
        nft.approve(address(auction), TOKEN_ID);
        
        vm.deal(buyer1, 20 ether);
        vm.deal(buyer2, 20 ether);
    }
    
    function testVeryShortAuction() public {
        vm.prank(seller);
        MockNFT shortNft = new MockNFT();
        
        vm.prank(seller);
        shortNft.mintWithId(seller, 2);
        
        // 1 second auction
        vm.prank(seller);
        DutchAuction shortAuction = new DutchAuction(
            address(shortNft),
            2,
            STARTING_PRICE,
            RESERVE_PRICE,
            1
        );
        
        vm.prank(seller);
        shortNft.approve(address(shortAuction), 2);
        
        // Purchase immediately at starting price
        uint256 currentPrice = shortAuction.getCurrentPrice();
        assertEq(currentPrice, STARTING_PRICE);
        
        // Move 1 second forward
        vm.warp(block.timestamp + 1);
        currentPrice = shortAuction.getCurrentPrice();
        assertEq(currentPrice, RESERVE_PRICE);
    }
    
    function testVeryLongAuction() public {
        vm.prank(seller);
        MockNFT longNft = new MockNFT();
        
        vm.prank(seller);
        longNft.mintWithId(seller, 3);
        
        // 30 day auction
        uint256 longDuration = 30 days;
        vm.prank(seller);
        DutchAuction longAuction = new DutchAuction(
            address(longNft),
            3,
            STARTING_PRICE,
            RESERVE_PRICE,
            longDuration
        );
        
        vm.prank(seller);
        longNft.approve(address(longAuction), 3);
        
        // Check price after 15 days (halfway)
        vm.warp(block.timestamp + 15 days);
        uint256 currentPrice = longAuction.getCurrentPrice();
        uint256 expectedPrice = STARTING_PRICE - ((STARTING_PRICE - RESERVE_PRICE) / 2);
        
        assertEq(currentPrice, expectedPrice);
    }
    
    function testHighPrecisionPriceCalculation() public {
        vm.prank(seller);
        MockNFT precisionNft = new MockNFT();
        
        vm.prank(seller);
        precisionNft.mintWithId(seller, 4);
        
        // Test with very precise pricing
        uint256 preciseStartPrice = 1234567890123456789; // ~1.23 ETH
        uint256 preciseReservePrice = 123456789012345678;  // ~0.123 ETH
        uint256 preciseDuration = 12345; // odd number for precision test
        
        vm.prank(seller);
        DutchAuction precisionAuction = new DutchAuction(
            address(precisionNft),
            4,
            preciseStartPrice,
            preciseReservePrice,
            preciseDuration
        );
        
        vm.prank(seller);
        precisionNft.approve(address(precisionAuction), 4);
        
        // Check price at various points
        vm.warp(block.timestamp + 1234); // ~10% through
        uint256 currentPrice = precisionAuction.getCurrentPrice();
        
        // Should be approximately 90% of the way from start to reserve
        uint256 expectedDecline = ((preciseStartPrice - preciseReservePrice) * 1234) / preciseDuration;
        uint256 expectedPrice = preciseStartPrice - expectedDecline;
        
        assertEq(currentPrice, expectedPrice);
    }
    
    function testMinimalPriceDifference() public {
        vm.prank(seller);
        MockNFT minNft = new MockNFT();
        
        vm.prank(seller);
        minNft.mintWithId(seller, 5);
        
        // Minimal price difference (1 wei)
        uint256 minStartPrice = 1000;
        uint256 minReservePrice = 999;
        
        vm.prank(seller);
        DutchAuction minAuction = new DutchAuction(
            address(minNft),
            5,
            minStartPrice,
            minReservePrice,
            DURATION
        );
        
        vm.prank(seller);
        minNft.approve(address(minAuction), 5);
        
        assertEq(minAuction.getCurrentPrice(), minStartPrice);
        
        // Move to end
        vm.warp(block.timestamp + DURATION);
        assertEq(minAuction.getCurrentPrice(), minReservePrice);
    }
    
    function testMaximumEtherValues() public {
        vm.prank(seller);
        MockNFT maxNft = new MockNFT();
        
        vm.prank(seller);
        maxNft.mintWithId(seller, 6);
        
        // Use large but reasonable values
        uint256 maxStartPrice = 1000000 ether;
        uint256 maxReservePrice = 100000 ether;
        
        vm.prank(seller);
        DutchAuction maxAuction = new DutchAuction(
            address(maxNft),
            6,
            maxStartPrice,
            maxReservePrice,
            DURATION
        );
        
        assertEq(maxAuction.getCurrentPrice(), maxStartPrice);
        
        vm.warp(block.timestamp + DURATION / 2);
        uint256 currentPrice = maxAuction.getCurrentPrice();
        uint256 expectedPrice = maxStartPrice - ((maxStartPrice - maxReservePrice) / 2);
        
        assertEq(currentPrice, expectedPrice);
    }
    
    function testMultipleWithdrawals() public {
        uint256 currentPrice = auction.getCurrentPrice();
        uint256 overpayment = 5 ether;
        
        // Buyer purchases with overpayment
        vm.prank(buyer1);
        auction.purchase{value: currentPrice + overpayment}();
        
        // Both seller and buyer have pending withdrawals
        assertEq(auction.pendingWithdrawals(seller), currentPrice);
        assertEq(auction.pendingWithdrawals(buyer1), overpayment);
        
        // Seller withdraws first
        uint256 sellerBalanceBefore = seller.balance;
        vm.prank(seller);
        auction.withdraw();
        
        assertEq(seller.balance, sellerBalanceBefore + currentPrice);
        assertEq(auction.pendingWithdrawals(seller), 0);
        assertEq(auction.pendingWithdrawals(buyer1), overpayment); // Buyer's amount unchanged
        
        // Buyer withdraws second
        uint256 buyerBalanceBefore = buyer1.balance;
        vm.prank(buyer1);
        auction.withdraw();
        
        assertEq(buyer1.balance, buyerBalanceBefore + overpayment);
        assertEq(auction.pendingWithdrawals(buyer1), 0);
    }
    
    function testZeroOverpayment() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        // Buyer pays exact amount
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        // Only seller should have pending withdrawal
        assertEq(auction.pendingWithdrawals(seller), currentPrice);
        assertEq(auction.pendingWithdrawals(buyer1), 0);
        
        // Buyer cannot withdraw anything
        vm.prank(buyer1);
        vm.expectRevert(DutchAuction.NoFundsToWithdraw.selector);
        auction.withdraw();
    }
    
    function testAuctionInfoAfterPurchase() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        (
            address nftContractAddr,
            uint256 nftTokenId,
            uint256 startPrice,
            uint256 reservePrice_,
            uint256 startTime_,
            uint256 duration_,
            uint256 currentPrice_,
            bool isActive,
            address winner_,
            uint256 finalPrice_
        ) = auction.getAuctionInfo();
        
        assertEq(nftContractAddr, address(nft));
        assertEq(nftTokenId, TOKEN_ID);
        assertEq(startPrice, STARTING_PRICE);
        assertEq(reservePrice_, RESERVE_PRICE);
        assertEq(currentPrice_, RESERVE_PRICE); // Should return reserve after auction ends
        assertFalse(isActive);
        assertEq(winner_, buyer1);
        assertEq(finalPrice_, currentPrice);
    }
    
    function testCannotEndAuctionTwice() public {
        vm.warp(block.timestamp + DURATION + 1);
        
        vm.prank(seller);
        auction.endAuction();
        
        vm.prank(seller);
        vm.expectRevert(DutchAuction.AuctionAlreadyEnded.selector);
        auction.endAuction();
    }
    
    function testCannotEndAuctionAfterPurchase() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        vm.warp(block.timestamp + DURATION + 1);
        
        vm.prank(seller);
        vm.expectRevert(DutchAuction.AuctionAlreadyEnded.selector);
        auction.endAuction();
    }
    
    function testNonOwnerCannotEndAuction() public {
        vm.warp(block.timestamp + DURATION + 1);
        
        vm.prank(buyer1);
        vm.expectRevert(); // Should revert with Ownable error
        auction.endAuction();
    }
}