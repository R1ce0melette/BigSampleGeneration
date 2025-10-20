// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, REFUNDED }
    
    struct EscrowTransaction {
        uint256 id;
        address payable buyer;
        address payable seller;
        address mediator;
        uint256 amount;
        State state;
        uint256 createdAt;
    }
    
    uint256 public transactionCount;
    mapping(uint256 => EscrowTransaction) public transactions;
    
    // Events
    event EscrowCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event PaymentDeposited(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed transactionId, address indexed buyer);
    event FundsReleased(uint256 indexed transactionId, address indexed seller, uint256 amount);
    event DisputeRaised(uint256 indexed transactionId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed transactionId, address indexed resolvedBy, address winner);
    event Refunded(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    
    /**
     * @dev Create a new escrow transaction
     * @param _seller The seller address
     * @param _mediator The mediator address
     */
    function createEscrow(address payable _seller, address _mediator) external payable {
        require(_seller != address(0), "Invalid seller address");
        require(_mediator != address(0), "Invalid mediator address");
        require(msg.value > 0, "Amount must be greater than 0");
        require(msg.sender != _seller, "Buyer and seller cannot be the same");
        require(msg.sender != _mediator, "Buyer and mediator cannot be the same");
        require(_seller != _mediator, "Seller and mediator cannot be the same");
        
        transactionCount++;
        
        transactions[transactionCount] = EscrowTransaction({
            id: transactionCount,
            buyer: payable(msg.sender),
            seller: _seller,
            mediator: _mediator,
            amount: msg.value,
            state: State.AWAITING_DELIVERY,
            createdAt: block.timestamp
        });
        
        emit EscrowCreated(transactionCount, msg.sender, _seller, _mediator, msg.value);
        emit PaymentDeposited(transactionCount, msg.sender, msg.value);
    }
    
    /**
     * @dev Buyer confirms delivery and releases funds to seller
     * @param _transactionId The ID of the transaction
     */
    function confirmDelivery(uint256 _transactionId) external {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        
        EscrowTransaction storage txn = transactions[_transactionId];
        
        require(msg.sender == txn.buyer, "Only buyer can confirm delivery");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid state");
        
        txn.state = State.COMPLETE;
        
        (bool success, ) = txn.seller.call{value: txn.amount}("");
        require(success, "Transfer to seller failed");
        
        emit DeliveryConfirmed(_transactionId, msg.sender);
        emit FundsReleased(_transactionId, txn.seller, txn.amount);
    }
    
    /**
     * @dev Raise a dispute
     * @param _transactionId The ID of the transaction
     */
    function raiseDispute(uint256 _transactionId) external {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        
        EscrowTransaction storage txn = transactions[_transactionId];
        
        require(
            msg.sender == txn.buyer || msg.sender == txn.seller,
            "Only buyer or seller can raise a dispute"
        );
        require(txn.state == State.AWAITING_DELIVERY, "Invalid state");
        
        txn.state = State.DISPUTED;
        
        emit DisputeRaised(_transactionId, msg.sender);
    }
    
    /**
     * @dev Mediator resolves dispute in favor of buyer or seller
     * @param _transactionId The ID of the transaction
     * @param _favorBuyer True to refund buyer, false to pay seller
     */
    function resolveDispute(uint256 _transactionId, bool _favorBuyer) external {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        
        EscrowTransaction storage txn = transactions[_transactionId];
        
        require(msg.sender == txn.mediator, "Only mediator can resolve dispute");
        require(txn.state == State.DISPUTED, "Transaction is not in disputed state");
        
        address payable recipient;
        
        if (_favorBuyer) {
            txn.state = State.REFUNDED;
            recipient = txn.buyer;
            
            (bool success, ) = recipient.call{value: txn.amount}("");
            require(success, "Refund to buyer failed");
            
            emit Refunded(_transactionId, txn.buyer, txn.amount);
            emit DisputeResolved(_transactionId, msg.sender, txn.buyer);
        } else {
            txn.state = State.COMPLETE;
            recipient = txn.seller;
            
            (bool success, ) = recipient.call{value: txn.amount}("");
            require(success, "Payment to seller failed");
            
            emit FundsReleased(_transactionId, txn.seller, txn.amount);
            emit DisputeResolved(_transactionId, msg.sender, txn.seller);
        }
    }
    
    /**
     * @dev Get transaction details
     * @param _transactionId The ID of the transaction
     * @return id The transaction ID
     * @return buyer The buyer address
     * @return seller The seller address
     * @return mediator The mediator address
     * @return amount The escrowed amount
     * @return state The current state
     * @return createdAt The creation timestamp
     */
    function getTransaction(uint256 _transactionId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state,
        uint256 createdAt
    ) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        
        EscrowTransaction memory txn = transactions[_transactionId];
        
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
     * @param _transactionId The ID of the transaction
     * @return The current state of the transaction
     */
    function getTransactionState(uint256 _transactionId) external view returns (State) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        
        return transactions[_transactionId].state;
    }
    
    /**
     * @dev Check if a user is involved in a transaction
     * @param _transactionId The ID of the transaction
     * @param _user The address to check
     * @return role The role of the user (0=none, 1=buyer, 2=seller, 3=mediator)
     */
    function getUserRole(uint256 _transactionId, address _user) external view returns (uint8 role) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        
        EscrowTransaction memory txn = transactions[_transactionId];
        
        if (_user == txn.buyer) return 1;
        if (_user == txn.seller) return 2;
        if (_user == txn.mediator) return 3;
        return 0;
    }
}
