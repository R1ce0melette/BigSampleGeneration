// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, REFUNDED }
    
    struct EscrowTransaction {
        uint256 transactionId;
        address payable buyer;
        address payable seller;
        address mediator;
        uint256 amount;
        State state;
        uint256 createdAt;
    }
    
    uint256 public transactionCount;
    mapping(uint256 => EscrowTransaction) public transactions;
    
    event TransactionCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, address mediator, uint256 amount);
    event PaymentDeposited(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    event DeliveryConfirmed(uint256 indexed transactionId, address indexed buyer);
    event PaymentReleased(uint256 indexed transactionId, address indexed seller, uint256 amount);
    event DisputeRaised(uint256 indexed transactionId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed transactionId, address indexed resolvedBy, bool buyerWins);
    event TransactionRefunded(uint256 indexed transactionId, address indexed buyer, uint256 amount);
    
    modifier onlyBuyer(uint256 _transactionId) {
        require(msg.sender == transactions[_transactionId].buyer, "Only buyer can call this");
        _;
    }
    
    modifier onlySeller(uint256 _transactionId) {
        require(msg.sender == transactions[_transactionId].seller, "Only seller can call this");
        _;
    }
    
    modifier onlyMediator(uint256 _transactionId) {
        require(msg.sender == transactions[_transactionId].mediator, "Only mediator can call this");
        _;
    }
    
    modifier inState(uint256 _transactionId, State _state) {
        require(transactions[_transactionId].state == _state, "Invalid state for this operation");
        _;
    }
    
    function createTransaction(address payable _seller, address _mediator) external payable returns (uint256) {
        require(msg.value > 0, "Payment amount must be greater than 0");
        require(_seller != address(0), "Seller address cannot be zero");
        require(_mediator != address(0), "Mediator address cannot be zero");
        require(_seller != msg.sender, "Buyer and seller cannot be the same");
        
        transactionCount++;
        
        transactions[transactionCount] = EscrowTransaction({
            transactionId: transactionCount,
            buyer: payable(msg.sender),
            seller: _seller,
            mediator: _mediator,
            amount: msg.value,
            state: State.AWAITING_DELIVERY,
            createdAt: block.timestamp
        });
        
        emit TransactionCreated(transactionCount, msg.sender, _seller, _mediator, msg.value);
        emit PaymentDeposited(transactionCount, msg.sender, msg.value);
        
        return transactionCount;
    }
    
    function confirmDelivery(uint256 _transactionId) external 
        onlyBuyer(_transactionId) 
        inState(_transactionId, State.AWAITING_DELIVERY) 
    {
        EscrowTransaction storage transaction = transactions[_transactionId];
        
        transaction.state = State.COMPLETE;
        
        (bool success, ) = transaction.seller.call{value: transaction.amount}("");
        require(success, "Payment transfer failed");
        
        emit DeliveryConfirmed(_transactionId, msg.sender);
        emit PaymentReleased(_transactionId, transaction.seller, transaction.amount);
    }
    
    function raiseDispute(uint256 _transactionId) external inState(_transactionId, State.AWAITING_DELIVERY) {
        EscrowTransaction storage transaction = transactions[_transactionId];
        require(
            msg.sender == transaction.buyer || msg.sender == transaction.seller,
            "Only buyer or seller can raise a dispute"
        );
        
        transaction.state = State.DISPUTED;
        
        emit DisputeRaised(_transactionId, msg.sender);
    }
    
    function resolveDispute(uint256 _transactionId, bool _buyerWins) external 
        onlyMediator(_transactionId) 
        inState(_transactionId, State.DISPUTED) 
    {
        EscrowTransaction storage transaction = transactions[_transactionId];
        
        if (_buyerWins) {
            transaction.state = State.REFUNDED;
            (bool success, ) = transaction.buyer.call{value: transaction.amount}("");
            require(success, "Refund transfer failed");
            emit TransactionRefunded(_transactionId, transaction.buyer, transaction.amount);
        } else {
            transaction.state = State.COMPLETE;
            (bool success, ) = transaction.seller.call{value: transaction.amount}("");
            require(success, "Payment transfer failed");
            emit PaymentReleased(_transactionId, transaction.seller, transaction.amount);
        }
        
        emit DisputeResolved(_transactionId, msg.sender, _buyerWins);
    }
    
    function getTransaction(uint256 _transactionId) external view returns (
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state,
        uint256 createdAt
    ) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        EscrowTransaction memory transaction = transactions[_transactionId];
        
        return (
            transaction.buyer,
            transaction.seller,
            transaction.mediator,
            transaction.amount,
            transaction.state,
            transaction.createdAt
        );
    }
    
    function getTransactionState(uint256 _transactionId) external view returns (State) {
        require(_transactionId > 0 && _transactionId <= transactionCount, "Invalid transaction ID");
        return transactions[_transactionId].state;
    }
}
