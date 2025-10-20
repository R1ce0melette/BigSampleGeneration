// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleEscrow {
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
        require(_buyer != address(0) && _seller != address(0) && _mediator != address(0), "Invalid address");
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
    }

    function fund() external payable {
        require(msg.sender == buyer, "Only buyer");
        require(!funded, "Already funded");
        require(msg.value > 0, "No ETH sent");
        amount = msg.value;
        funded = true;
        emit Funded(msg.sender, msg.value);
    }

    function releaseToSeller() external {
        require(funded && !released, "Not available");
        require(msg.sender == buyer || msg.sender == mediator, "Not authorized");
        released = true;
        (bool sent, ) = seller.call{value: amount}("");
        require(sent, "Transfer failed");
        emit Released(seller, amount);
    }

    function refundToBuyer() external {
        require(funded && !released, "Not available");
        require(msg.sender == seller || msg.sender == mediator, "Not authorized");
        released = true;
        (bool sent, ) = buyer.call{value: amount}("");
        require(sent, "Refund failed");
        emit Refunded(buyer, amount);
    }
}
