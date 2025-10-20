// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Distributor {
    address public owner;

    event Distributed(address[] recipients, uint256 amountPerRecipient);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function distribute(address payable[] memory _recipients) public payable onlyOwner {
        require(_recipients.length > 0, "Must have at least one recipient.");
        require(msg.value > 0, "Must send some ETH to distribute.");
        
        uint256 amountPerRecipient = msg.value / _recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient must be greater than zero.");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(amountPerRecipient);
        }

        // If there's any remainder, send it back to the owner
        uint256 remainder = msg.value % _recipients.length;
        if (remainder > 0) {
            payable(owner).transfer(remainder);
        }

        emit Distributed(_recipients, amountPerRecipient);
    }
}
