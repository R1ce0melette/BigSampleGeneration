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
        bool buyerApproved;
        bool sellerApproved;
    }
    
    uint256 public transactionCount;
    mapping(uint256 => EscrowTransaction) public transactions;
    
    event TransactionCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event PaymentDeposited(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed transactionId, address indexed buyer);
    event FundsReleased(uint256 indexed transactionId, address indexed seller, uint256 amount);
    event DisputeRaised(uint256 indexed transactionId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed transactionId, address indexed resolvedBy, address winner);
    event Refunded(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    
    function createTransaction(address payable _seller, address _mediator) external payable {
        require(_seller != address(0), "Invalid seller address");
        require(_mediator != address(0), "Invalid mediator address");
        require(msg.value > 0, "Payment amount must be greater than zero");
        require(_seller != msg.sender, "Buyer and seller cannot be the same");
        require(_mediator != msg.sender && _mediator != _seller, "Mediator must be different from buyer and seller");
        
        transactionCount++;
        
        transactions[transactionCount] = EscrowTransaction({
            id: transactionCount,
            buyer: payable(msg.sender),
            seller: _seller,
            mediator: _mediator,
            amount: msg.value,
            state: State.AWAITING_DELIVERY,
            buyerApproved: false,
            sellerApproved: false
        });
        
        emit TransactionCreated(transactionCount, msg.sender, _seller, _mediator, msg.value);
        emit PaymentDeposited(transactionCount, msg.sender, msg.value);
    }
    
    function confirmDelivery(uint256 _transactionId) external {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Transaction does not exist");
        
        EscrowTransaction storage txn = transactions[_transactionId];
        
        require(msg.sender == txn.buyer, "Only buyer can confirm delivery");
        require(txn.state == State.AWAITING_DELIVERY, "Transaction is not awaiting delivery");
        
        txn.state = State.COMPLETE;
        
        (bool success, ) = txn.seller.call{value: txn.amount}("");
        require(success, "Transfer to seller failed");
        
        emit DeliveryConfirmed(_transactionId, msg.sender);
        emit FundsReleased(_transactionId, txn.seller, txn.amount);
    }
    
    function raiseDispute(uint256 _transactionId) external {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Transaction does not exist");
        
        EscrowTransaction storage txn = transactions[_transactionId];
        
        require(msg.sender == txn.buyer || msg.sender == txn.seller, "Only buyer or seller can raise dispute");
        require(txn.state == State.AWAITING_DELIVERY, "Transaction is not in valid state for dispute");
        
        txn.state = State.DISPUTED;
        
        emit DisputeRaised(_transactionId, msg.sender);
    }
    
    function resolveDispute(uint256 _transactionId, bool _favorBuyer) external {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Transaction does not exist");
        
        EscrowTransaction storage txn = transactions[_transactionId];
        
        require(msg.sender == txn.mediator, "Only mediator can resolve dispute");
        require(txn.state == State.DISPUTED, "Transaction is not disputed");
        
        address payable winner;
        
        if (_favorBuyer) {
            txn.state = State.REFUNDED;
            winner = txn.buyer;
            
            (bool success, ) = txn.buyer.call{value: txn.amount}("");
            require(success, "Refund to buyer failed");
            
            emit Refunded(_transactionId, txn.buyer, txn.amount);
        } else {
            txn.state = State.COMPLETE;
            winner = txn.seller;
            
            (bool success, ) = txn.seller.call{value: txn.amount}("");
            require(success, "Transfer to seller failed");
            
            emit FundsReleased(_transactionId, txn.seller, txn.amount);
        }
        
        emit DisputeResolved(_transactionId, msg.sender, winner);
    }
    
    function getTransaction(uint256 _transactionId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state
    ) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Transaction does not exist");
        
        EscrowTransaction memory txn = transactions[_transactionId];
        
        return (
            txn.id,
            txn.buyer,
            txn.seller,
            txn.mediator,
            txn.amount,
            txn.state
        );
    }
    
    function getTransactionState(uint256 _transactionId) external view returns (State) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Transaction does not exist");
        return transactions[_transactionId].state;
    }
}
