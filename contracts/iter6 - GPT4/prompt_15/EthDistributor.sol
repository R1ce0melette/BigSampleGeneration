// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    address public owner;

    event Distributed(address[] recipients, uint256 amountPerRecipient);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distribute(address[] calldata recipients) external payable onlyOwner {
        require(recipients.length > 0, "No recipients");
        require(msg.value > 0, "No ETH sent");
        uint256 amountPerRecipient = msg.value / recipients.length;
        require(amountPerRecipient > 0, "ETH too low");
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: amountPerRecipient}("");
            require(sent, "Transfer failed");
        }
        emit Distributed(recipients, amountPerRecipient);
    }
}
