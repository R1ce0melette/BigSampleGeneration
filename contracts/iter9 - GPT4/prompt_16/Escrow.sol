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

    constructor(address _buyer, address _seller, address _mediator) {
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
    }

    function fund() external payable {
        require(msg.sender == buyer, "Only buyer can fund");
        require(!funded, "Already funded");
        require(msg.value > 0, "No ETH sent");
        amount = msg.value;
        funded = true;
        emit Funded(msg.sender, msg.value);
    }

    function releaseToSeller() external {
        require(funded, "Not funded");
        require(!released, "Already released");
        require(msg.sender == buyer || msg.sender == mediator, "Not authorized");
        released = true;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    function refundToBuyer() external {
        require(funded, "Not funded");
        require(!released, "Already released");
        require(msg.sender == seller || msg.sender == mediator, "Not authorized");
        released = true;
        payable(buyer).transfer(amount);
        emit Refunded(buyer, amount);
    }
}
