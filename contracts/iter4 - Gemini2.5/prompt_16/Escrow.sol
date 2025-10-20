// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address payable public seller;
    address public mediator;
    uint256 public amount;

    enum State { AwaitingPayment, AwaitingRelease, Released, Disputed, Resolved }
    State public currentState;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event FundsReleased(address indexed seller, uint256 amount);
    event DisputeOpened(address indexed by);
    event DisputeResolved(address indexed mediator, address indexed winner, uint256 amount);

    constructor(address payable _seller, address _mediator) {
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
        currentState = State.AwaitingPayment;
    }

    function deposit() public payable {
        require(msg.sender == buyer, "Only the buyer can deposit funds.");
        require(currentState == State.AwaitingPayment, "Escrow is not awaiting payment.");
        amount = msg.value;
        currentState = State.AwaitingRelease;
        emit FundsDeposited(buyer, amount);
    }

    function release() public {
        require(msg.sender == buyer, "Only the buyer can release funds.");
        require(currentState == State.AwaitingRelease, "Escrow is not awaiting release.");
        
        currentState = State.Released;
        seller.transfer(amount);
        emit FundsReleased(seller, amount);
    }

    function openDispute() public {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can open a dispute.");
        require(currentState == State.AwaitingRelease, "Can only open dispute while awaiting release.");
        
        currentState = State.Disputed;
        emit DisputeOpened(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) public {
        require(msg.sender == mediator, "Only the mediator can resolve disputes.");
        require(currentState == State.Disputed, "Escrow is not in a disputed state.");

        currentState = State.Resolved;
        if (_releaseToSeller) {
            seller.transfer(amount);
            emit DisputeResolved(mediator, seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit DisputeResolved(mediator, buyer, amount);
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
