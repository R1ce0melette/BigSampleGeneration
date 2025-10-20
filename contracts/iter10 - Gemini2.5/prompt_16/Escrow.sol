// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isDisputed;

    event Funded(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Disputed(address indexed party);
    event Resolved(address indexed winner, uint256 amount);

    modifier onlyParties() {
        require(msg.sender == buyer || msg.sender == seller || msg.sender == mediator, "Only parties can call this function.");
        _;
    }

    constructor(address _buyer, address _seller, address _mediator) {
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
    }

    function fund() public payable {
        require(msg.sender == buyer, "Only the buyer can fund the escrow.");
        require(!isFunded, "Escrow is already funded.");
        amount = msg.value;
        isFunded = true;
        emit Funded(buyer, amount);
    }

    function release() public {
        require(msg.sender == buyer, "Only the buyer can release funds.");
        require(isFunded, "Escrow is not funded.");
        require(!isReleased, "Funds have already been released.");
        require(!isDisputed, "A dispute is active.");

        isReleased = true;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    function dispute() public {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can raise a dispute.");
        require(isFunded, "Escrow is not funded.");
        require(!isReleased, "Funds have already been released.");
        isDisputed = true;
        emit Disputed(msg.sender);
    }

    function resolve(address _winner) public {
        require(msg.sender == mediator, "Only the mediator can resolve disputes.");
        require(isDisputed, "No dispute is active.");
        require(_winner == buyer || _winner == seller, "Winner must be either buyer or seller.");

        isReleased = true;
        payable(_winner).transfer(amount);
        emit Resolved(_winner, amount);
    }
}
