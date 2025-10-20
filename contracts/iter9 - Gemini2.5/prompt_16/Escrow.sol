// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;

    enum State { AwaitingPayment, AwaitingDelivery, Complete, InDispute, Resolved }
    State public currentState;

    event Funded(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);
    event Dispute(address indexed party);
    event ResolvedByMediator(address indexed winner, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function.");
        _;
    }
    
    modifier onlyMediator() {
        require(msg.sender == mediator, "Only mediator can call this function.");
        _;
    }

    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this action.");
        _;
    }

    constructor(address _seller, address _mediator) {
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
        currentState = State.AwaitingPayment;
    }

    function fund() public payable onlyBuyer inState(State.AwaitingPayment) {
        amount = msg.value;
        currentState = State.AwaitingDelivery;
        emit Funded(buyer, amount);
    }

    function release() public onlySeller inState(State.AwaitingDelivery) {
        currentState = State.Complete;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    function refund() public onlyBuyer inState(State.AwaitingDelivery) {
        currentState = State.Complete;
        payable(buyer).transfer(amount);
        emit Refunded(buyer, amount);
    }

    function raiseDispute() public inState(State.AwaitingDelivery) {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise a dispute.");
        currentState = State.InDispute;
        emit Dispute(msg.sender);
    }

    function resolveDispute(address _winner) public onlyMediator inState(State.InDispute) {
        require(_winner == buyer || _winner == seller, "Winner must be either buyer or seller.");
        currentState = State.Resolved;
        payable(_winner).transfer(amount);
        emit ResolvedByMediator(_winner, amount);
    }
}
