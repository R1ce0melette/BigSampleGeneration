// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Distributor {
    address public owner;

    event Distributed(address[] recipients, uint256 amountPerRecipient);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distribute(address payable[] memory _recipients) public payable onlyOwner {
        require(_recipients.length > 0, "At least one recipient is required.");
        require(msg.value > 0, "Distribution amount must be greater than zero.");
        
        uint256 amountPerRecipient = msg.value / _recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient must be greater than zero.");

        for (uint i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(amountPerRecipient);
        }

        // Refund any remaining dust to the owner
        uint256 remainder = msg.value % _recipients.length;
        if (remainder > 0) {
            payable(owner).transfer(remainder);
        }

        emit Distributed(_recipients, amountPerRecipient);
    }
}
