// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthDistributor {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distribute(address[] calldata recipients) external payable onlyOwner {
        require(recipients.length > 0, "No recipients");
        uint256 amount = msg.value / recipients.length;
        require(amount > 0, "Insufficient ETH");
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amount);
        }
    }
}
