// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    address public owner;

    event Distributed(address[] recipients, uint256 amountEach);

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
        uint256 amountEach = msg.value / recipients.length;
        require(amountEach > 0, "Amount too small");
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: amountEach}("");
            require(sent, "Transfer failed");
        }
        emit Distributed(recipients, amountEach);
    }
}
