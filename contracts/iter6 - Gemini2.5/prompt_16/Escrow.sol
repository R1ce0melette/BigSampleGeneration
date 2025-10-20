// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;

    enum State { AwaitingPayment, AwaitingDelivery, Complete, InDispute, Resolved }
    State public currentState;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event FundsReleased(address indexed seller, uint256 amount);
    event DisputeOpened(address indexed by);
    event DisputeResolved(address indexed mediator, address indexed winner);

    constructor(address _buyer, address _seller, address _mediator) {
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
        currentState = State.AwaitingPayment;
    }

    function deposit() public payable {
        require(msg.sender == buyer, "Only buyer can deposit.");
        require(currentState == State.AwaitingPayment, "Already paid.");
        amount = msg.value;
        currentState = State.AwaitingDelivery;
        emit FundsDeposited(buyer, amount);
    }

    function release() public {
        require(msg.sender == buyer, "Only buyer can release funds.");
        require(currentState == State.AwaitingDelivery, "Funds cannot be released yet.");
        currentState = State.Complete;
        payable(seller).transfer(amount);
        emit FundsReleased(seller, amount);
    }

    function openDispute() public {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can open a dispute.");
        require(currentState == State.AwaitingDelivery, "Can only dispute while awaiting delivery.");
        currentState = State.InDispute;
        emit DisputeOpened(msg.sender);
    }

    function resolveDispute(address _winner) public {
        require(msg.sender == mediator, "Only mediator can resolve disputes.");
        require(currentState == State.InDispute, "No dispute to resolve.");
        require(_winner == buyer || _winner == seller, "Winner must be buyer or seller.");
        
        currentState = State.Resolved;
        payable(_winner).transfer(amount);
        emit DisputeResolved(mediator, _winner);
    }
}
