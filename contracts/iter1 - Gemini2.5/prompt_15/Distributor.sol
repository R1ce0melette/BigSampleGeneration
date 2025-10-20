// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Distributor {
    address public owner;

    event Distributed(address indexed recipient, uint256 amount);
    event RemainderSent(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distribute(address payable[] calldata recipients) public payable onlyOwner {
        uint256 recipientCount = recipients.length;
        require(recipientCount > 0, "Recipients list cannot be empty.");
        require(msg.value > 0, "Must send some ETH to distribute.");

        uint256 amountPerRecipient = msg.value / recipientCount;
        uint256 remainder = msg.value % recipientCount;

        require(amountPerRecipient > 0, "Amount per recipient must be greater than zero.");

        for (uint i = 0; i < recipientCount; i++) {
            recipients[i].transfer(amountPerRecipient);
            emit Distributed(recipients[i], amountPerRecipient);
        }

        if (remainder > 0) {
            payable(owner).transfer(remainder);
            emit RemainderSent(owner, remainder);
        }
    }

    // Allow owner to withdraw any ETH accidentally sent to the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        payable(owner).transfer(balance);
    }
}
