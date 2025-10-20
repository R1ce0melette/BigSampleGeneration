// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleEscrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;

    enum State { Created, Locked, Released, Refunded, Disputed }
    State public currentState;

    event EscrowCreated(address indexed buyer, address indexed seller, address indexed mediator, uint256 amount);
    event FundsLocked();
    event FundsReleased(address indexed seller, uint256 amount);
    event FundsRefunded(address indexed buyer, uint256 amount);
    event DisputeOpened(address indexed by);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function.");
        _;
    }
    
    modifier onlyMediator() {
        require(msg.sender == mediator, "Only the mediator can call this function.");
        _;
    }

    constructor(address _seller, address _mediator) {
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
        currentState = State.Created;
        emit EscrowCreated(buyer, seller, mediator, 0);
    }

    function lock() public payable {
        require(currentState == State.Created, "Escrow not in created state.");
        require(msg.sender == buyer, "Only buyer can lock funds.");
        amount = msg.value;
        require(amount > 0, "Amount must be greater than zero.");
        currentState = State.Locked;
        emit FundsLocked();
    }

    function release() public {
        require(currentState == State.Locked, "Funds are not locked.");
        require(msg.sender == buyer || msg.sender == mediator, "Only buyer or mediator can release funds.");
        currentState = State.Released;
        payable(seller).transfer(amount);
        emit FundsReleased(seller, amount);
    }

    function refund() public {
        require(currentState == State.Locked, "Funds are not locked.");
        require(msg.sender == seller || msg.sender == mediator, "Only seller or mediator can refund.");
        currentState = State.Refunded;
        payable(buyer).transfer(amount);
        emit FundsRefunded(buyer, amount);
    }

    function openDispute() public {
        require(currentState == State.Locked, "Can only open dispute when funds are locked.");
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can open a dispute.");
        currentState = State.Disputed;
        emit DisputeOpened(msg.sender);
    }
}
