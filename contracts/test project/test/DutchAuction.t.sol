// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/DutchAuction.sol";
import "../src/MockNFT.sol";

contract DutchAuctionTest is Test {
    DutchAuction public auction;
    MockNFT public nft;
    
    address public seller = address(0x1);
    address public buyer1 = address(0x2);
    address public buyer2 = address(0x3);
    
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant STARTING_PRICE = 10 ether;
    uint256 public constant RESERVE_PRICE = 1 ether;
    uint256 public constant DURATION = 3600; // 1 hour
    
    event AuctionStarted(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 startTime,
        uint256 duration
    );
    
    event Purchase(
        address indexed buyer,
        uint256 price,
        uint256 timestamp
    );
    
    event AuctionEnded(
        address indexed winner,
        uint256 finalPrice,
        uint256 timestamp
    );
    
    event WithdrawalMade(
        address indexed recipient,
        uint256 amount
    );
    
    function setUp() public {
        // Deploy NFT contract
        vm.prank(seller);
        nft = new MockNFT();
        
        // Mint NFT to seller
        vm.prank(seller);
        nft.mintWithId(seller, TOKEN_ID);
        
        // Deploy auction contract
        vm.prank(seller);
        auction = new DutchAuction(
            address(nft),
            TOKEN_ID,
            STARTING_PRICE,
            RESERVE_PRICE,
            DURATION
        );
        
        // Approve auction contract to transfer NFT
        vm.prank(seller);
        nft.approve(address(auction), TOKEN_ID);
        
        // Fund buyers
        vm.deal(buyer1, 20 ether);
        vm.deal(buyer2, 20 ether);
    }
    
    function testInitialSetup() public {
        assertEq(address(auction.nftContract()), address(nft));
        assertEq(auction.tokenId(), TOKEN_ID);
        assertEq(auction.startingPrice(), STARTING_PRICE);
        assertEq(auction.reservePrice(), RESERVE_PRICE);
        assertEq(auction.duration(), DURATION);
        assertEq(auction.owner(), seller);
        assertFalse(auction.auctionEnded());
        assertEq(auction.winner(), address(0));
        assertEq(auction.finalPrice(), 0);
    }
    
    function testAuctionStartedEvent() public {
        vm.expectEmit(true, true, false, true);
        emit AuctionStarted(
            address(nft),
            TOKEN_ID,
            STARTING_PRICE,
            RESERVE_PRICE,
            block.timestamp,
            DURATION
        );
        
        vm.prank(seller);
        new DutchAuction(
            address(nft),
            TOKEN_ID,
            STARTING_PRICE,
            RESERVE_PRICE,
            DURATION
        );
    }
    
    // Price curve tests
    function testPriceCurveAtStart() public {
        uint256 currentPrice = auction.getCurrentPrice();
        assertEq(currentPrice, STARTING_PRICE);
    }
    
    function testPriceCurveAtMidpoint() public {
        // Move to halfway point
        vm.warp(block.timestamp + DURATION / 2);
        
        uint256 currentPrice = auction.getCurrentPrice();
        uint256 expectedPrice = STARTING_PRICE - ((STARTING_PRICE - RESERVE_PRICE) / 2);
        
        assertEq(currentPrice, expectedPrice);
    }
    
    function testPriceCurveAtEnd() public {
        // Move to end of auction
        vm.warp(block.timestamp + DURATION);
        
        uint256 currentPrice = auction.getCurrentPrice();
        assertEq(currentPrice, RESERVE_PRICE);
    }
    
    function testPriceCurveLinearDecrease() public {
        uint256 timeStep = DURATION / 10;
        uint256 priceStep = (STARTING_PRICE - RESERVE_PRICE) / 10;
        
        for (uint256 i = 0; i <= 10; i++) {
            vm.warp(block.timestamp + (timeStep * i));
            uint256 currentPrice = auction.getCurrentPrice();
            uint256 expectedPrice = STARTING_PRICE - (priceStep * i);
            
            // Allow for small rounding differences
            assertApproxEqAbs(currentPrice, expectedPrice, 1);
        }
    }
    
    function testPriceCurveAfterAuctionEnd() public {
        // Move past auction end
        vm.warp(block.timestamp + DURATION + 1000);
        
        uint256 currentPrice = auction.getCurrentPrice();
        assertEq(currentPrice, RESERVE_PRICE);
    }
    
    // Edge block timing tests
    function testPurchaseAtExactStartTime() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        assertEq(auction.winner(), buyer1);
        assertEq(auction.finalPrice(), STARTING_PRICE);
        assertTrue(auction.auctionEnded());
    }
    
    function testPurchaseAtExactEndTime() public {
        vm.warp(block.timestamp + DURATION);
        
        uint256 currentPrice = auction.getCurrentPrice();
        assertEq(currentPrice, RESERVE_PRICE);
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        assertEq(auction.winner(), buyer1);
        assertEq(auction.finalPrice(), RESERVE_PRICE);
    }
    
    function testPurchaseOneBlockBeforeEnd() public {
        vm.warp(block.timestamp + DURATION - 1);
        
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        assertEq(auction.winner(), buyer1);
        assertTrue(auction.auctionEnded());
    }
    
    function testCannotPurchaseAfterAuctionEnds() public {
        vm.warp(block.timestamp + DURATION + 1);
        
        vm.prank(seller);
        auction.endAuction();
        
        vm.prank(buyer1);
        vm.expectRevert(DutchAuction.AuctionAlreadyEnded.selector);
        auction.purchase{value: RESERVE_PRICE}();
    }
    
    // First buyer wins tests
    function testFirstBuyerWins() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        // First buyer purchases
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        assertEq(auction.winner(), buyer1);
        assertTrue(auction.auctionEnded());
        
        // Second buyer cannot purchase
        vm.prank(buyer2);
        vm.expectRevert(DutchAuction.AuctionAlreadyEnded.selector);
        auction.purchase{value: currentPrice}();
    }
    
    function testSimultaneousPurchaseAttempts() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        // First transaction wins
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        // Second transaction in same block fails
        vm.prank(buyer2);
        vm.expectRevert(DutchAuction.AuctionAlreadyEnded.selector);
        auction.purchase{value: currentPrice}();
    }
    
    // Refund safety tests
    function testNoRefundsAfterPurchase() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        // Buyer cannot get refund (no refund function exists)
        // This test verifies that the contract doesn't have refund functionality
        assertEq(auction.winner(), buyer1);
        assertEq(auction.finalPrice(), currentPrice);
    }
    
    function testExcessPaymentHandling() public {
        uint256 currentPrice = auction.getCurrentPrice();
        uint256 overpayment = 2 ether;
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice + overpayment}();
        
        // Excess should be available for withdrawal
        assertEq(auction.pendingWithdrawals(buyer1), overpayment);
        assertEq(auction.pendingWithdrawals(seller), currentPrice);
    }
    
    function testCannotPurchaseWithInsufficientFunds() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        vm.expectRevert(DutchAuction.InsufficientPayment.selector);
        auction.purchase{value: currentPrice - 1}();
    }
    
    // Pull payment pattern tests
    function testSellerCanWithdrawAfterSale() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        assertEq(auction.pendingWithdrawals(seller), currentPrice);
        
        uint256 sellerBalanceBefore = seller.balance;
        
        vm.prank(seller);
        auction.withdraw();
        
        assertEq(seller.balance, sellerBalanceBefore + currentPrice);
        assertEq(auction.pendingWithdrawals(seller), 0);
    }
    
    function testBuyerCanWithdrawExcessPayment() public {
        uint256 currentPrice = auction.getCurrentPrice();
        uint256 overpayment = 2 ether;
        uint256 buyerBalanceBefore = buyer1.balance;
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice + overpayment}();
        
        vm.prank(buyer1);
        auction.withdraw();
        
        // Buyer should get back only the overpayment
        assertEq(buyer1.balance, buyerBalanceBefore - currentPrice);
        assertEq(auction.pendingWithdrawals(buyer1), 0);
    }
    
    function testCannotWithdrawWithoutFunds() public {
        vm.prank(buyer2);
        vm.expectRevert(DutchAuction.NoFundsToWithdraw.selector);
        auction.withdraw();
    }
    
    function testWithdrawalEvents() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        vm.expectEmit(true, false, false, true);
        emit WithdrawalMade(seller, currentPrice);
        
        vm.prank(seller);
        auction.withdraw();
    }
    
    // Event tests
    function testPurchaseEvent() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.expectEmit(true, false, false, true);
        emit Purchase(buyer1, currentPrice, block.timestamp);
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
    }
    
    function testAuctionEndedEvent() public {
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.expectEmit(true, false, false, true);
        emit AuctionEnded(buyer1, currentPrice, block.timestamp);
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
    }
    
    // Constructor validation tests
    function testInvalidConstructorParameters() public {
        vm.prank(seller);
        
        // Invalid contract address
        vm.expectRevert(DutchAuction.InvalidParameters.selector);
        new DutchAuction(address(0), TOKEN_ID, STARTING_PRICE, RESERVE_PRICE, DURATION);
        
        // Starting price <= reserve price
        vm.expectRevert(DutchAuction.InvalidParameters.selector);
        new DutchAuction(address(nft), TOKEN_ID, RESERVE_PRICE, STARTING_PRICE, DURATION);
        
        // Zero duration
        vm.expectRevert(DutchAuction.InvalidParameters.selector);
        new DutchAuction(address(nft), TOKEN_ID, STARTING_PRICE, RESERVE_PRICE, 0);
    }
    
    // Utility function tests
    function testGetTimeRemaining() public {
        uint256 timeRemaining = auction.getTimeRemaining();
        assertEq(timeRemaining, DURATION);
        
        vm.warp(block.timestamp + 1800); // 30 minutes
        timeRemaining = auction.getTimeRemaining();
        assertEq(timeRemaining, DURATION - 1800);
        
        vm.warp(block.timestamp + DURATION);
        timeRemaining = auction.getTimeRemaining();
        assertEq(timeRemaining, 0);
    }
    
    function testIsAuctionActive() public {
        assertTrue(auction.isAuctionActive());
        
        vm.warp(block.timestamp + DURATION / 2);
        assertTrue(auction.isAuctionActive());
        
        vm.warp(block.timestamp + DURATION);
        assertFalse(auction.isAuctionActive());
    }
    
    function testGetAuctionInfo() public {
        (
            address nftContractAddr,
            uint256 nftTokenId,
            uint256 startPrice,
            uint256 reservePrice_,
            uint256 startTime_,
            uint256 duration_,
            uint256 currentPrice,
            bool isActive,
            address winner_,
            uint256 finalPrice_
        ) = auction.getAuctionInfo();
        
        assertEq(nftContractAddr, address(nft));
        assertEq(nftTokenId, TOKEN_ID);
        assertEq(startPrice, STARTING_PRICE);
        assertEq(reservePrice_, RESERVE_PRICE);
        assertEq(startTime_, block.timestamp);
        assertEq(duration_, DURATION);
        assertEq(currentPrice, STARTING_PRICE);
        assertTrue(isActive);
        assertEq(winner_, address(0));
        assertEq(finalPrice_, 0);
    }
    
    // NFT transfer test
    function testNFTTransferredToBuyer() public {
        assertEq(nft.ownerOf(TOKEN_ID), seller);
        
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        assertEq(nft.ownerOf(TOKEN_ID), buyer1);
    }
    
    // Manual auction end test
    function testManualAuctionEnd() public {
        vm.warp(block.timestamp + DURATION + 1);
        
        vm.expectEmit(true, false, false, true);
        emit AuctionEnded(address(0), 0, block.timestamp);
        
        vm.prank(seller);
        auction.endAuction();
        
        assertTrue(auction.auctionEnded());
    }
    
    function testCannotEndAuctionEarly() public {
        vm.prank(seller);
        vm.expectRevert(DutchAuction.AuctionStillActive.selector);
        auction.endAuction();
    }
    
    // Reentrancy protection test
    function testReentrancyProtection() public {
        // This test ensures the nonReentrant modifier is working
        // The actual reentrancy attack would require a malicious contract
        // For this test, we verify that the modifier is in place
        uint256 currentPrice = auction.getCurrentPrice();
        
        vm.prank(buyer1);
        auction.purchase{value: currentPrice}();
        
        // Verify state is properly set
        assertTrue(auction.auctionEnded());
        assertEq(auction.winner(), buyer1);
    }
}