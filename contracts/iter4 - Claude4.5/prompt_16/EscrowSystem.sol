// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EscrowSystem
 * @dev A simple escrow system between a buyer and a seller with a mediator to resolve disputes
 */
contract EscrowSystem {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, REFUNDED }
    
    struct Escrow {
        uint256 id;
        address payable buyer;
        address payable seller;
        address mediator;
        uint256 amount;
        State state;
        uint256 createdAt;
        string description;
    }
    
    uint256 public escrowCount;
    mapping(uint256 => Escrow) public escrows;
    
    // Events
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event PaymentDeposited(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed escrowId, address indexed buyer);
    event PaymentReleased(uint256 indexed escrowId, address indexed seller, uint256 amount);
    event DisputeRaised(uint256 indexed escrowId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed escrowId, address indexed resolvedBy, bool buyerWins);
    event EscrowRefunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    
    /**
     * @dev Creates a new escrow
     * @param _seller The seller's address
     * @param _mediator The mediator's address
     * @param _description Description of the transaction
     */
    function createEscrow(
        address payable _seller,
        address _mediator,
        string memory _description
    ) external payable {
        require(_seller != address(0), "Invalid seller address");
        require(_mediator != address(0), "Invalid mediator address");
        require(msg.sender != _seller, "Buyer and seller cannot be the same");
        require(msg.sender != _mediator, "Buyer and mediator cannot be the same");
        require(_seller != _mediator, "Seller and mediator cannot be the same");
        require(msg.value > 0, "Escrow amount must be greater than 0");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        escrowCount++;
        
        escrows[escrowCount] = Escrow({
            id: escrowCount,
            buyer: payable(msg.sender),
            seller: _seller,
            mediator: _mediator,
            amount: msg.value,
            state: State.AWAITING_DELIVERY,
            createdAt: block.timestamp,
            description: _description
        });
        
        emit EscrowCreated(escrowCount, msg.sender, _seller, _mediator, msg.value);
        emit PaymentDeposited(escrowCount, msg.sender, msg.value);
    }
    
    /**
     * @dev Buyer confirms delivery and releases payment to seller
     * @param _escrowId The ID of the escrow
     */
    function confirmDelivery(uint256 _escrowId) external {
        require(_escrowId > 0 && _escrowId <= escrowCount, "Invalid escrow ID");
        
        Escrow storage escrow = escrows[_escrowId];
        
        require(msg.sender == escrow.buyer, "Only buyer can confirm delivery");
        require(escrow.state == State.AWAITING_DELIVERY, "Invalid escrow state");
        
        escrow.state = State.COMPLETE;
        
        emit DeliveryConfirmed(_escrowId, msg.sender);
        
        // Release payment to seller
        (bool success, ) = escrow.seller.call{value: escrow.amount}("");
        require(success, "Payment transfer failed");
        
        emit PaymentReleased(_escrowId, escrow.seller, escrow.amount);
    }
    
    /**
     * @dev Raise a dispute (can be called by buyer or seller)
     * @param _escrowId The ID of the escrow
     */
    function raiseDispute(uint256 _escrowId) external {
        require(_escrowId > 0 && _escrowId <= escrowCount, "Invalid escrow ID");
        
        Escrow storage escrow = escrows[_escrowId];
        
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, 
                "Only buyer or seller can raise dispute");
        require(escrow.state == State.AWAITING_DELIVERY, "Invalid escrow state");
        
        escrow.state = State.DISPUTED;
        
        emit DisputeRaised(_escrowId, msg.sender);
    }
    
    /**
     * @dev Mediator resolves the dispute
     * @param _escrowId The ID of the escrow
     * @param _buyerWins True if buyer wins, false if seller wins
     */
    function resolveDispute(uint256 _escrowId, bool _buyerWins) external {
        require(_escrowId > 0 && _escrowId <= escrowCount, "Invalid escrow ID");
        
        Escrow storage escrow = escrows[_escrowId];
        
        require(msg.sender == escrow.mediator, "Only mediator can resolve dispute");
        require(escrow.state == State.DISPUTED, "Escrow is not in disputed state");
        
        if (_buyerWins) {
            escrow.state = State.REFUNDED;
            
            (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
            require(success, "Refund transfer failed");
            
            emit EscrowRefunded(_escrowId, escrow.buyer, escrow.amount);
        } else {
            escrow.state = State.COMPLETE;
            
            (bool success, ) = escrow.seller.call{value: escrow.amount}("");
            require(success, "Payment transfer failed");
            
            emit PaymentReleased(_escrowId, escrow.seller, escrow.amount);
        }
        
        emit DisputeResolved(_escrowId, msg.sender, _buyerWins);
    }
    
    /**
     * @dev Returns the details of an escrow
     * @param _escrowId The ID of the escrow
     * @return id The escrow ID
     * @return buyer The buyer's address
     * @return seller The seller's address
     * @return mediator The mediator's address
     * @return amount The escrow amount
     * @return state The current state
     * @return createdAt When the escrow was created
     * @return description The transaction description
     */
    function getEscrow(uint256 _escrowId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state,
        uint256 createdAt,
        string memory description
    ) {
        require(_escrowId > 0 && _escrowId <= escrowCount, "Invalid escrow ID");
        
        Escrow memory escrow = escrows[_escrowId];
        
        return (
            escrow.id,
            escrow.buyer,
            escrow.seller,
            escrow.mediator,
            escrow.amount,
            escrow.state,
            escrow.createdAt,
            escrow.description
        );
    }
    
    /**
     * @dev Returns all escrows where the caller is involved
     * @return Array of escrow IDs
     */
    function getMyEscrows() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count escrows where caller is involved
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].buyer == msg.sender || 
                escrows[i].seller == msg.sender || 
                escrows[i].mediator == msg.sender) {
                count++;
            }
        }
        
        // Create array of escrow IDs
        uint256[] memory myEscrows = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].buyer == msg.sender || 
                escrows[i].seller == msg.sender || 
                escrows[i].mediator == msg.sender) {
                myEscrows[index] = i;
                index++;
            }
        }
        
        return myEscrows;
    }
    
    /**
     * @dev Returns escrows where the caller is the buyer
     * @return Array of escrow IDs
     */
    function getMyBuyerEscrows() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].buyer == msg.sender) {
                count++;
            }
        }
        
        uint256[] memory buyerEscrows = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].buyer == msg.sender) {
                buyerEscrows[index] = i;
                index++;
            }
        }
        
        return buyerEscrows;
    }
    
    /**
     * @dev Returns escrows where the caller is the seller
     * @return Array of escrow IDs
     */
    function getMySellerEscrows() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].seller == msg.sender) {
                count++;
            }
        }
        
        uint256[] memory sellerEscrows = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].seller == msg.sender) {
                sellerEscrows[index] = i;
                index++;
            }
        }
        
        return sellerEscrows;
    }
    
    /**
     * @dev Returns disputed escrows where the caller is the mediator
     * @return Array of escrow IDs
     */
    function getDisputedEscrows() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].mediator == msg.sender && escrows[i].state == State.DISPUTED) {
                count++;
            }
        }
        
        uint256[] memory disputedEscrows = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (escrows[i].mediator == msg.sender && escrows[i].state == State.DISPUTED) {
                disputedEscrows[index] = i;
                index++;
            }
        }
        
        return disputedEscrows;
    }
    
    /**
     * @dev Returns the state of an escrow as a string
     * @param _escrowId The ID of the escrow
     * @return The state as a string
     */
    function getEscrowState(uint256 _escrowId) external view returns (string memory) {
        require(_escrowId > 0 && _escrowId <= escrowCount, "Invalid escrow ID");
        
        State state = escrows[_escrowId].state;
        
        if (state == State.AWAITING_PAYMENT) return "AWAITING_PAYMENT";
        if (state == State.AWAITING_DELIVERY) return "AWAITING_DELIVERY";
        if (state == State.COMPLETE) return "COMPLETE";
        if (state == State.DISPUTED) return "DISPUTED";
        if (state == State.REFUNDED) return "REFUNDED";
        
        return "UNKNOWN";
    }
}
