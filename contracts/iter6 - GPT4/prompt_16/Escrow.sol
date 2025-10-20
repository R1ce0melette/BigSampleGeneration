// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    bool public buyerApproved;
    bool public sellerApproved;
    bool public disputed;
    bool public resolved;

    event Deposited(address indexed buyer, uint256 amount);
    event Approved(address indexed party);
    event Disputed();
    event Resolved(address indexed to);

    constructor(address _buyer, address _seller, address _mediator) {
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Not buyer");
        require(amount == 0, "Already deposited");
        require(msg.value > 0, "No ETH sent");
        amount = msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function approve() external {
        require(msg.sender == buyer || msg.sender == seller, "Not party");
        if (msg.sender == buyer) buyerApproved = true;
        if (msg.sender == seller) sellerApproved = true;
        emit Approved(msg.sender);
        if (buyerApproved && sellerApproved && !disputed) {
            _release(seller);
        }
    }

    function dispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not party");
        require(!disputed, "Already disputed");
        disputed = true;
        emit Disputed();
    }

    function resolve(address to) external {
        require(msg.sender == mediator, "Not mediator");
        require(disputed, "No dispute");
        require(!resolved, "Already resolved");
        _release(to);
        resolved = true;
        emit Resolved(to);
    }

    function _release(address to) internal {
        require(amount > 0, "No funds");
        uint256 payout = amount;
        amount = 0;
        (bool sent, ) = to.call{value: payout}("");
        require(sent, "Transfer failed");
    }
}
