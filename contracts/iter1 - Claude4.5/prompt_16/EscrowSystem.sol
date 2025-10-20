// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EscrowSystem
 * @dev A simple escrow system between a buyer and a seller with a mediator to resolve disputes
 */
contract EscrowSystem {
    enum EscrowState {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE,
        DISPUTE,
        REFUNDED,
        CANCELLED
    }
    
    struct Escrow {
        uint256 id;
        address payable buyer;
        address payable seller;
        address mediator;
        uint256 amount;
        EscrowState state;
        uint256 createdAt;
        uint256 completedAt;
        string description;
    }
    
    uint256 private escrowCounter;
    mapping(uint256 => Escrow) public escrows;
    
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address mediator,
        uint256 amount
    );
    
    event PaymentDeposited(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed escrowId, address indexed buyer);
    event DisputeRaised(uint256 indexed escrowId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed escrowId, address winner);
    event EscrowRefunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCancelled(uint256 indexed escrowId);
    
    /**
     * @dev Create a new escrow
     * @param seller The seller's address
     * @param mediator The mediator's address
     * @param description Description of the transaction
     * @return escrowId The ID of the created escrow
     */
    function createEscrow(
        address payable seller,
        address mediator,
        string memory description
    ) external payable returns (uint256) {
        require(msg.value > 0, "Escrow amount must be greater than 0");
        require(seller != address(0), "Invalid seller address");
        require(mediator != address(0), "Invalid mediator address");
        require(seller != msg.sender, "Buyer and seller cannot be the same");
        require(mediator != msg.sender && mediator != seller, "Invalid mediator");
        
        escrowCounter++;
        uint256 escrowId = escrowCounter;
        
        escrows[escrowId] = Escrow({
            id: escrowId,
            buyer: payable(msg.sender),
            seller: seller,
            mediator: mediator,
            amount: msg.value,
            state: EscrowState.AWAITING_DELIVERY,
            createdAt: block.timestamp,
            completedAt: 0,
            description: description
        });
        
        emit EscrowCreated(escrowId, msg.sender, seller, mediator, msg.value);
        emit PaymentDeposited(escrowId, msg.sender, msg.value);
        
        return escrowId;
    }
    
    /**
     * @dev Buyer confirms delivery and releases payment to seller
     * @param escrowId The ID of the escrow
     */
    function confirmDelivery(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        
        require(escrow.id != 0, "Escrow does not exist");
        require(msg.sender == escrow.buyer, "Only buyer can confirm delivery");
        require(escrow.state == EscrowState.AWAITING_DELIVERY, "Invalid escrow state");
        
        escrow.state = EscrowState.COMPLETE;
        escrow.completedAt = block.timestamp;
        
        (bool success, ) = escrow.seller.call{value: escrow.amount}("");
        require(success, "Transfer to seller failed");
        
        emit DeliveryConfirmed(escrowId, msg.sender);
    }
    
    /**
     * @dev Raise a dispute
     * @param escrowId The ID of the escrow
     */
    function raiseDispute(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        
        require(escrow.id != 0, "Escrow does not exist");
        require(
            msg.sender == escrow.buyer || msg.sender == escrow.seller,
            "Only buyer or seller can raise dispute"
        );
        require(escrow.state == EscrowState.AWAITING_DELIVERY, "Invalid escrow state");
        
        escrow.state = EscrowState.DISPUTE;
        
        emit DisputeRaised(escrowId, msg.sender);
    }
    
    /**
     * @dev Mediator resolves dispute in favor of buyer (refund)
     * @param escrowId The ID of the escrow
     */
    function resolveDisputeForBuyer(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        
        require(escrow.id != 0, "Escrow does not exist");
        require(msg.sender == escrow.mediator, "Only mediator can resolve dispute");
        require(escrow.state == EscrowState.DISPUTE, "No active dispute");
        
        escrow.state = EscrowState.REFUNDED;
        escrow.completedAt = block.timestamp;
        
        (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
        require(success, "Refund to buyer failed");
        
        emit DisputeResolved(escrowId, escrow.buyer);
        emit EscrowRefunded(escrowId, escrow.buyer, escrow.amount);
    }
    
    /**
     * @dev Mediator resolves dispute in favor of seller (release payment)
     * @param escrowId The ID of the escrow
     */
    function resolveDisputeForSeller(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        
        require(escrow.id != 0, "Escrow does not exist");
        require(msg.sender == escrow.mediator, "Only mediator can resolve dispute");
        require(escrow.state == EscrowState.DISPUTE, "No active dispute");
        
        escrow.state = EscrowState.COMPLETE;
        escrow.completedAt = block.timestamp;
        
        (bool success, ) = escrow.seller.call{value: escrow.amount}("");
        require(success, "Transfer to seller failed");
        
        emit DisputeResolved(escrowId, escrow.seller);
    }
    
    /**
     * @dev Cancel escrow before payment (not used in current flow but for future extension)
     * @param escrowId The ID of the escrow
     */
    function cancelEscrow(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        
        require(escrow.id != 0, "Escrow does not exist");
        require(
            msg.sender == escrow.buyer || msg.sender == escrow.seller,
            "Only buyer or seller can cancel"
        );
        require(escrow.state == EscrowState.AWAITING_PAYMENT, "Cannot cancel after payment");
        
        escrow.state = EscrowState.CANCELLED;
        escrow.completedAt = block.timestamp;
        
        emit EscrowCancelled(escrowId);
    }
    
    /**
     * @dev Get escrow details
     * @param escrowId The ID of the escrow
     * @return id Escrow ID
     * @return buyer Buyer address
     * @return seller Seller address
     * @return mediator Mediator address
     * @return amount Escrow amount
     * @return state Current state
     * @return createdAt Creation timestamp
     * @return completedAt Completion timestamp
     * @return description Transaction description
     */
    function getEscrowDetails(uint256 escrowId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        EscrowState state,
        uint256 createdAt,
        uint256 completedAt,
        string memory description
    ) {
        Escrow memory escrow = escrows[escrowId];
        require(escrow.id != 0, "Escrow does not exist");
        
        return (
            escrow.id,
            escrow.buyer,
            escrow.seller,
            escrow.mediator,
            escrow.amount,
            escrow.state,
            escrow.createdAt,
            escrow.completedAt,
            escrow.description
        );
    }
    
    /**
     * @dev Get escrows by buyer
     * @param buyer The buyer's address
     * @return Array of escrow IDs
     */
    function getEscrowsByBuyer(address buyer) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count escrows
        for (uint256 i = 1; i <= escrowCounter; i++) {
            if (escrows[i].buyer == buyer) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory escrowIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCounter; i++) {
            if (escrows[i].buyer == buyer) {
                escrowIds[index] = i;
                index++;
            }
        }
        
        return escrowIds;
    }
    
    /**
     * @dev Get escrows by seller
     * @param seller The seller's address
     * @return Array of escrow IDs
     */
    function getEscrowsBySeller(address seller) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count escrows
        for (uint256 i = 1; i <= escrowCounter; i++) {
            if (escrows[i].seller == seller) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory escrowIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCounter; i++) {
            if (escrows[i].seller == seller) {
                escrowIds[index] = i;
                index++;
            }
        }
        
        return escrowIds;
    }
    
    /**
     * @dev Get escrows by mediator
     * @param mediator The mediator's address
     * @return Array of escrow IDs
     */
    function getEscrowsByMediator(address mediator) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count escrows
        for (uint256 i = 1; i <= escrowCounter; i++) {
            if (escrows[i].mediator == mediator) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory escrowIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCounter; i++) {
            if (escrows[i].mediator == mediator) {
                escrowIds[index] = i;
                index++;
            }
        }
        
        return escrowIds;
    }
    
    /**
     * @dev Get total number of escrows
     * @return The total count
     */
    function getTotalEscrows() external view returns (uint256) {
        return escrowCounter;
    }
    
    /**
     * @dev Check if an escrow is in dispute
     * @param escrowId The ID of the escrow
     * @return Whether the escrow is in dispute
     */
    function isInDispute(uint256 escrowId) external view returns (bool) {
        require(escrows[escrowId].id != 0, "Escrow does not exist");
        return escrows[escrowId].state == EscrowState.DISPUTE;
    }
    
    /**
     * @dev Get the state of an escrow
     * @param escrowId The ID of the escrow
     * @return The current state
     */
    function getEscrowState(uint256 escrowId) external view returns (EscrowState) {
        require(escrows[escrowId].id != 0, "Escrow does not exist");
        return escrows[escrowId].state;
    }
}
