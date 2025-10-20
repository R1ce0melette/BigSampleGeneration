// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED }
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    State public state;

    event Deposited(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    constructor(address _seller, address _mediator) {
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
        state = State.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer");
        require(state == State.AWAITING_PAYMENT, "Not awaiting payment");
        require(msg.value > 0, "No ETH sent");
        amount = msg.value;
        state = State.AWAITING_DELIVERY;
        emit Deposited(msg.sender, msg.value);
    }

    function release() external {
        require(state == State.AWAITING_DELIVERY, "Not awaiting delivery");
        require(msg.sender == buyer || msg.sender == mediator, "Not authorized");
        state = State.COMPLETE;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    function refund() external {
        require(state == State.AWAITING_DELIVERY, "Not awaiting delivery");
        require(msg.sender == seller || msg.sender == mediator, "Not authorized");
        state = State.REFUNDED;
        payable(buyer).transfer(amount);
        emit Refunded(buyer, amount);
    }
}
