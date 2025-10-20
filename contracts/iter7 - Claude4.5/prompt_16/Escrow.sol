// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Escrow
 * @dev A simple escrow system between a buyer and a seller with a mediator to resolve disputes
 */
contract Escrow {
    // Escrow states
    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE,
        REFUNDED,
        DISPUTED
    }
    
    // Escrow transaction structure
    struct Transaction {
        uint256 id;
        address payable buyer;
        address payable seller;
        address mediator;
        uint256 amount;
        State state;
        bool buyerApproved;
        bool sellerApproved;
        uint256 createdAt;
    }
    
    // State variables
    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    
    // Events
    event TransactionCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event PaymentDeposited(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed transactionId, address indexed buyer);
    event PaymentReleased(uint256 indexed transactionId, address indexed seller, uint256 amount);
    event PaymentRefunded(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DisputeRaised(uint256 indexed transactionId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed transactionId, address indexed resolvedBy, bool buyerWins);
    
    /**
     * @dev Create a new escrow transaction
     * @param seller The seller's address
     * @param mediator The mediator's address
     * @return transactionId The ID of the created transaction
     */
    function createTransaction(address payable seller, address mediator) external payable returns (uint256) {
        require(msg.value > 0, "Transaction amount must be greater than 0");
        require(seller != address(0), "Invalid seller address");
        require(mediator != address(0), "Invalid mediator address");
        require(seller != msg.sender, "Buyer and seller cannot be the same");
        require(mediator != msg.sender && mediator != seller, "Mediator must be different from buyer and seller");
        
        transactionCount++;
        uint256 transactionId = transactionCount;
        
        Transaction storage txn = transactions[transactionId];
        txn.id = transactionId;
        txn.buyer = payable(msg.sender);
        txn.seller = seller;
        txn.mediator = mediator;
        txn.amount = msg.value;
        txn.state = State.AWAITING_DELIVERY;
        txn.buyerApproved = false;
        txn.sellerApproved = false;
        txn.createdAt = block.timestamp;
        
        emit TransactionCreated(transactionId, msg.sender, seller, mediator, msg.value);
        emit PaymentDeposited(transactionId, msg.sender, msg.value);
        
        return transactionId;
    }
    
    /**
     * @dev Buyer confirms delivery and approves payment release
     * @param transactionId The ID of the transaction
     */
    function confirmDelivery(uint256 transactionId) external {
        Transaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer, "Only buyer can confirm delivery");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        
        txn.buyerApproved = true;
        
        emit DeliveryConfirmed(transactionId, msg.sender);
        
        // If seller also approved or buyer confirms, release payment
        if (txn.sellerApproved || txn.buyerApproved) {
            _releasePayment(transactionId);
        }
    }
    
    /**
     * @dev Seller confirms they can release the payment (optional, buyer confirmation is enough)
     * @param transactionId The ID of the transaction
     */
    function sellerConfirm(uint256 transactionId) external {
        Transaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.seller, "Only seller can confirm");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        
        txn.sellerApproved = true;
        
        // Release payment if buyer also approved
        if (txn.buyerApproved) {
            _releasePayment(transactionId);
        }
    }
    
    /**
     * @dev Internal function to release payment to seller
     * @param transactionId The ID of the transaction
     */
    function _releasePayment(uint256 transactionId) internal {
        Transaction storage txn = transactions[transactionId];
        
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        
        txn.state = State.COMPLETE;
        
        (bool success, ) = txn.seller.call{value: txn.amount}("");
        require(success, "Payment transfer failed");
        
        emit PaymentReleased(transactionId, txn.seller, txn.amount);
    }
    
    /**
     * @dev Raise a dispute
     * @param transactionId The ID of the transaction
     */
    function raiseDispute(uint256 transactionId) external {
        Transaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer || msg.sender == txn.seller, "Only buyer or seller can raise dispute");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        
        txn.state = State.DISPUTED;
        
        emit DisputeRaised(transactionId, msg.sender);
    }
    
    /**
     * @dev Mediator resolves the dispute
     * @param transactionId The ID of the transaction
     * @param buyerWins True if buyer wins (refund), false if seller wins (release payment)
     */
    function resolveDispute(uint256 transactionId, bool buyerWins) external {
        Transaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.mediator, "Only mediator can resolve dispute");
        require(txn.state == State.DISPUTED, "Transaction is not in disputed state");
        
        if (buyerWins) {
            txn.state = State.REFUNDED;
            
            (bool success, ) = txn.buyer.call{value: txn.amount}("");
            require(success, "Refund transfer failed");
            
            emit PaymentRefunded(transactionId, txn.buyer, txn.amount);
        } else {
            txn.state = State.COMPLETE;
            
            (bool success, ) = txn.seller.call{value: txn.amount}("");
            require(success, "Payment transfer failed");
            
            emit PaymentReleased(transactionId, txn.seller, txn.amount);
        }
        
        emit DisputeResolved(transactionId, msg.sender, buyerWins);
    }
    
    /**
     * @dev Buyer requests refund (only before delivery confirmation)
     * @param transactionId The ID of the transaction
     */
    function requestRefund(uint256 transactionId) external {
        Transaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer, "Only buyer can request refund");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        require(!txn.buyerApproved, "Cannot refund after confirming delivery");
        
        // Buyer can request refund, but it requires raising a dispute
        txn.state = State.DISPUTED;
        
        emit DisputeRaised(transactionId, msg.sender);
    }
    
    /**
     * @dev Get transaction details
     * @param transactionId The ID of the transaction
     * @return id Transaction ID
     * @return buyer Buyer's address
     * @return seller Seller's address
     * @return mediator Mediator's address
     * @return amount Transaction amount
     * @return state Current state
     * @return buyerApproved Whether buyer approved
     * @return sellerApproved Whether seller approved
     * @return createdAt Creation timestamp
     */
    function getTransaction(uint256 transactionId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state,
        bool buyerApproved,
        bool sellerApproved,
        uint256 createdAt
    ) {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        
        Transaction storage txn = transactions[transactionId];
        return (
            txn.id,
            txn.buyer,
            txn.seller,
            txn.mediator,
            txn.amount,
            txn.state,
            txn.buyerApproved,
            txn.sellerApproved,
            txn.createdAt
        );
    }
    
    /**
     * @dev Get transaction state
     * @param transactionId The ID of the transaction
     * @return The current state of the transaction
     */
    function getTransactionState(uint256 transactionId) external view returns (State) {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        return transactions[transactionId].state;
    }
    
    /**
     * @dev Check if caller is involved in a transaction
     * @param transactionId The ID of the transaction
     * @return role 0 = not involved, 1 = buyer, 2 = seller, 3 = mediator
     */
    function getMyRole(uint256 transactionId) external view returns (uint8) {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        
        Transaction storage txn = transactions[transactionId];
        
        if (msg.sender == txn.buyer) {
            return 1;
        } else if (msg.sender == txn.seller) {
            return 2;
        } else if (msg.sender == txn.mediator) {
            return 3;
        } else {
            return 0;
        }
    }
    
    /**
     * @dev Get all transactions where caller is buyer
     * @return Array of transaction IDs
     */
    function getMyBuyerTransactions() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count transactions
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].buyer == msg.sender) {
                count++;
            }
        }
        
        // Create array
        uint256[] memory txnIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].buyer == msg.sender) {
                txnIds[index] = i;
                index++;
            }
        }
        
        return txnIds;
    }
    
    /**
     * @dev Get all transactions where caller is seller
     * @return Array of transaction IDs
     */
    function getMySellerTransactions() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count transactions
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].seller == msg.sender) {
                count++;
            }
        }
        
        // Create array
        uint256[] memory txnIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].seller == msg.sender) {
                txnIds[index] = i;
                index++;
            }
        }
        
        return txnIds;
    }
}
