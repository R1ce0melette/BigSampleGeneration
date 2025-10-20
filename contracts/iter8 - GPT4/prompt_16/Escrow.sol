// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    enum State { AwaitingPayment, AwaitingDelivery, Complete, Disputed, Refunded }
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    State public state;

    event Deposited(address indexed buyer, uint256 amount);
    event Delivered(address indexed seller);
    event Refunded(address indexed buyer);
    event Disputed(address indexed by);
    event Resolved(address indexed to, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }
    modifier onlySeller() {
        require(msg.sender == seller, "Not seller");
        _;
    }
    modifier onlyMediator() {
        require(msg.sender == mediator, "Not mediator");
        _;
    }

    constructor(address _buyer, address _seller, address _mediator) {
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
        state = State.AwaitingPayment;
    }

    function deposit() external payable onlyBuyer {
        require(state == State.AwaitingPayment, "Not awaiting payment");
        require(msg.value > 0, "No ETH sent");
        amount = msg.value;
        state = State.AwaitingDelivery;
        emit Deposited(msg.sender, msg.value);
    }

    function confirmDelivery() external onlyBuyer {
        require(state == State.AwaitingDelivery, "Not awaiting delivery");
        state = State.Complete;
        payable(seller).transfer(amount);
        emit Delivered(seller);
    }

    function dispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not participant");
        require(state == State.AwaitingDelivery, "Cannot dispute now");
        state = State.Disputed;
        emit Disputed(msg.sender);
    }

    function resolveToBuyer() external onlyMediator {
        require(state == State.Disputed, "Not disputed");
        state = State.Refunded;
        payable(buyer).transfer(amount);
        emit Refunded(buyer);
        emit Resolved(buyer, amount);
    }

    function resolveToSeller() external onlyMediator {
        require(state == State.Disputed, "Not disputed");
        state = State.Complete;
        payable(seller).transfer(amount);
        emit Delivered(seller);
        emit Resolved(seller, amount);
    }
}
