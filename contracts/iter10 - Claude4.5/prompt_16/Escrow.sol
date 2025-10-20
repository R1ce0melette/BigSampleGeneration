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
    event DeliveryConfirmed(uint256 indexed transactionId);
    event DisputeRaised(uint256 indexed transactionId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed transactionId, address indexed resolvedBy, bool refundToBuyer);
    event FundsReleased(uint256 indexed transactionId, address indexed recipient, uint256 amount);
    event TransactionRefunded(uint256 indexed transactionId, address indexed buyer, uint256 amount);

    function createTransaction(address payable seller, address mediator) external payable {
        require(msg.value > 0, "Must send ETH for escrow");
        require(seller != address(0), "Invalid seller address");
        require(mediator != address(0), "Invalid mediator address");
        require(msg.sender != seller, "Buyer and seller must be different");
        require(msg.sender != mediator && seller != mediator, "Mediator must be different from buyer and seller");

        transactionCount++;
        
        transactions[transactionCount] = EscrowTransaction({
            id: transactionCount,
            buyer: payable(msg.sender),
            seller: seller,
            mediator: mediator,
            amount: msg.value,
            state: State.AWAITING_DELIVERY,
            buyerApproved: false,
            sellerApproved: false
        });

        emit TransactionCreated(transactionCount, msg.sender, seller, mediator, msg.value);
        emit PaymentDeposited(transactionCount, msg.sender, msg.value);
    }

    function confirmDelivery(uint256 transactionId) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Transaction does not exist");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer, "Only buyer can confirm delivery");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");

        txn.state = State.COMPLETE;
        
        (bool success, ) = txn.seller.call{value: txn.amount}("");
        require(success, "Transfer to seller failed");

        emit DeliveryConfirmed(transactionId);
        emit FundsReleased(transactionId, txn.seller, txn.amount);
    }

    function raiseDispute(uint256 transactionId) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Transaction does not exist");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.buyer || msg.sender == txn.seller, "Only buyer or seller can raise dispute");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");

        txn.state = State.DISPUTED;
        
        emit DisputeRaised(transactionId, msg.sender);
    }

    function resolveDispute(uint256 transactionId, bool refundToBuyer) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Transaction does not exist");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.mediator, "Only mediator can resolve dispute");
        require(txn.state == State.DISPUTED, "Transaction is not in disputed state");

        address payable recipient;
        
        if (refundToBuyer) {
            txn.state = State.REFUNDED;
            recipient = txn.buyer;
        } else {
            txn.state = State.COMPLETE;
            recipient = txn.seller;
        }

        (bool success, ) = recipient.call{value: txn.amount}("");
        require(success, "Transfer failed");

        emit DisputeResolved(transactionId, msg.sender, refundToBuyer);
        emit FundsReleased(transactionId, recipient, txn.amount);
    }

    function refundBuyer(uint256 transactionId) external {
        require(transactionId > 0 && transactionId <= transactionCount, "Transaction does not exist");
        EscrowTransaction storage txn = transactions[transactionId];
        
        require(msg.sender == txn.seller, "Only seller can initiate refund");
        require(txn.state == State.AWAITING_DELIVERY, "Invalid transaction state");

        txn.state = State.REFUNDED;
        
        (bool success, ) = txn.buyer.call{value: txn.amount}("");
        require(success, "Refund failed");

        emit TransactionRefunded(transactionId, txn.buyer, txn.amount);
    }

    function getTransaction(uint256 transactionId) external view returns (
        uint256 id,
        address buyer,
        address seller,
        address mediator,
        uint256 amount,
        State state
    ) {
        require(transactionId > 0 && transactionId <= transactionCount, "Transaction does not exist");
        EscrowTransaction memory txn = transactions[transactionId];
        return (txn.id, txn.buyer, txn.seller, txn.mediator, txn.amount, txn.state);
    }

    function getTransactionState(uint256 transactionId) external view returns (State) {
        require(transactionId > 0 && transactionId <= transactionCount, "Transaction does not exist");
        return transactions[transactionId].state;
    }
}
