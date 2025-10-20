// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {

    enum State { Created, Funded, Released, Disputed, Resolved }

    address payable public buyer;
    address payable public seller;
    address public mediator;
    uint256 public amount;
    State public currentState;

    event Funded(uint256 amount);
    event Released(address indexed recipient, uint256 amount);
    event Disputed();
    event Resolved(address indexed winner, uint256 amount);

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

    constructor(address payable _seller, address _mediator) {
        buyer = payable(msg.sender);
        seller = _seller;
        mediator = _mediator;
        currentState = State.Created;
    }

    function deposit() public payable onlyBuyer inState(State.Created) {
        require(msg.value > 0, "Must deposit a positive amount.");
        amount = msg.value;
        currentState = State.Funded;
        emit Funded(amount);
    }

    function release() public onlyBuyer inState(State.Funded) {
        currentState = State.Released;
        seller.transfer(amount);
        emit Released(seller, amount);
    }

    function raiseDispute() public inState(State.Funded) {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise a dispute.");
        currentState = State.Disputed;
        emit Disputed();
    }

    function resolveDispute(address payable _winner) public onlyMediator inState(State.Disputed) {
        require(_winner == buyer || _winner == seller, "Winner must be either buyer or seller.");
        currentState = State.Resolved;
        _winner.transfer(amount);
        emit Resolved(_winner, amount);
    }
}
