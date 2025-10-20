// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Escrow
 * @dev A simple escrow system between a buyer and a seller with a mediator to resolve disputes
 */
contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED, DISPUTED }
    
    struct EscrowTransaction {
        uint256 id;
        address payable buyer;
        address payable seller;
        address mediator;
        uint256 amount;
        State state;
        uint256 createdAt;
        bool mediatorPaid;
    }
    
    uint256 public transactionCount;
    mapping(uint256 => EscrowTransaction) public transactions;
    
    uint256 public mediatorFeePercent = 2; // 2% mediator fee
    
    // Events
    event EscrowCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event PaymentDeposited(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed transactionId, address indexed buyer);
    event PaymentReleased(uint256 indexed transactionId, address indexed seller, uint256 amount);
    event RefundIssued(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DisputeRaised(uint256 indexed transactionId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed transactionId, address indexed resolvedBy, bool buyerWins);
    
    /**
     * @dev Create a new escrow transaction
     * @param seller The seller's address
     * @param mediator The mediator's address
     */
    function createEscrow(address payable seller, address mediator) external payable {
        require(msg.value > 0, "Payment amount must be greater than 0");
        require(seller != address(0), "Invalid seller address");
        require(mediator != address(0), "Invalid mediator address");
        require(msg.sender != seller, "Buyer and seller cannot be the same");
        require(msg.sender != mediator, "Buyer and mediator cannot be the same");
        require(seller != mediator, "Seller and mediator cannot be the same");
        
        transactionCount++;
        
        transactions[transactionCount] = EscrowTransaction({
            id: transactionCount,
            buyer: payable(msg.sender),
            seller: seller,
            mediator: mediator,
            amount: msg.value,
            state: State.AWAITING_DELIVERY,
            createdAt: block.timestamp,
            mediatorPaid: false
        });
        
        emit EscrowCreated(transactionCount, msg.sender, seller, mediator, msg.value);
        emit PaymentDeposited(transactionCount, msg.sender, msg.value);
    }
    
    /**
     * @dev Buyer confirms delivery and releases payment to seller
     * @param transactionId The ID of the transaction
     */
    function confirmDelivery(uint256 transactionId) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer, "Only buyer can confirm delivery");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        
        txn.state = State.COMPLETE;
        
        (bool success, ) = txn.seller.call{value: txn.amount}("");
        require(success, "Transfer to seller failed");
        
        emit DeliveryConfirmed(transactionId, msg.sender);
        emit PaymentReleased(transactionId, txn.seller, txn.amount);
    }
    
    /**
     * @dev Raise a dispute
     * @param transactionId The ID of the transaction
     */
    function raiseDispute(uint256 transactionId) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer || msg.sender == txn.seller, "Only buyer or seller can raise dispute");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");
        
        txn.state = State.DISPUTED;
        
        emit DisputeRaised(transactionId, msg.sender);
    }
    
    /**
     * @dev Resolve a dispute (mediator only)
     * @param transactionId The ID of the transaction
     * @param buyerWins True if buyer wins, false if seller wins
     */
    function resolveDispute(uint256 transactionId, bool buyerWins) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.mediator, "Only mediator can resolve dispute");
        require(txn.state == State.DISPUTED, "Transaction is not disputed");
        
        uint256 mediatorFee = (txn.amount * mediatorFeePercent) / 100;
        uint256 remainingAmount = txn.amount - mediatorFee;
        
        // Pay mediator
        if (!txn.mediatorPaid && mediatorFee > 0) {
            txn.mediatorPaid = true;
            (bool mediatorSuccess, ) = txn.mediator.call{value: mediatorFee}("");
            require(mediatorSuccess, "Transfer to mediator failed");
        }
        
        if (buyerWins) {
            // Refund to buyer
            txn.state = State.REFUNDED;
            (bool success, ) = txn.buyer.call{value: remainingAmount}("");
            require(success, "Transfer to buyer failed");
            emit RefundIssued(transactionId, txn.buyer, remainingAmount);
        } else {
            // Pay seller
            txn.state = State.COMPLETE;
            (bool success, ) = txn.seller.call{value: remainingAmount}("");
            require(success, "Transfer to seller failed");
            emit PaymentReleased(transactionId, txn.seller, remainingAmount);
        }
        
        emit DisputeResolved(transactionId, msg.sender, buyerWins);
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
     * @return createdAt Creation timestamp
     */
    function getTransaction(uint256 transactionId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state,
        uint256 createdAt
    ) {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        EscrowTransaction memory txn = transactions[transactionId];
        
        return (
            txn.id,
            txn.buyer,
            txn.seller,
            txn.mediator,
            txn.amount,
            txn.state,
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
     * @dev Get all transactions for a buyer
     * @param buyer The buyer's address
     * @return Array of transaction IDs
     */
    function getTransactionsByBuyer(address buyer) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].buyer == buyer) {
                count++;
            }
        }
        
        uint256[] memory txnIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].buyer == buyer) {
                txnIds[index] = i;
                index++;
            }
        }
        
        return txnIds;
    }
    
    /**
     * @dev Get all transactions for a seller
     * @param seller The seller's address
     * @return Array of transaction IDs
     */
    function getTransactionsBySeller(address seller) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].seller == seller) {
                count++;
            }
        }
        
        uint256[] memory txnIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].seller == seller) {
                txnIds[index] = i;
                index++;
            }
        }
        
        return txnIds;
    }
    
    /**
     * @dev Get all transactions for a mediator
     * @param mediator The mediator's address
     * @return Array of transaction IDs
     */
    function getTransactionsByMediator(address mediator) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].mediator == mediator) {
                count++;
            }
        }
        
        uint256[] memory txnIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= transactionCount; i++) {
            if (transactions[i].mediator == mediator) {
                txnIds[index] = i;
                index++;
            }
        }
        
        return txnIds;
    }
    
    /**
     * @dev Check if transaction is disputed
     * @param transactionId The ID of the transaction
     * @return True if disputed, false otherwise
     */
    function isDisputed(uint256 transactionId) external view returns (bool) {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        return transactions[transactionId].state == State.DISPUTED;
    }
    
    /**
     * @dev Check if transaction is complete
     * @param transactionId The ID of the transaction
     * @return True if complete, false otherwise
     */
    function isComplete(uint256 transactionId) external view returns (bool) {
        require(transactionId > 0 && transactionId <= transactionCount, "Invalid transaction ID");
        return transactions[transactionId].state == State.COMPLETE;
    }
}
