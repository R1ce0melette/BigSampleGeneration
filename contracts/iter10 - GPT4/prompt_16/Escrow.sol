// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    bool public funded;
    bool public released;

    event Funded(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }
    modifier onlyMediator() {
        require(msg.sender == mediator, "Not mediator");
        _;
    }

    constructor(address _buyer, address _seller, address _mediator) {
        require(_buyer != address(0) && _seller != address(0) && _mediator != address(0), "Invalid address");
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
    }

    function fund() external payable onlyBuyer {
        require(!funded, "Already funded");
        require(msg.value > 0, "No ETH sent");
        amount = msg.value;
        funded = true;
        emit Funded(msg.sender, msg.value);
    }

    function releaseToSeller() external onlyMediator {
        require(funded && !released, "Not funded or already released");
        released = true;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    function refundToBuyer() external onlyMediator {
        require(funded && !released, "Not funded or already released");
        released = true;
        payable(buyer).transfer(amount);
        emit Refunded(buyer, amount);
    }
}
