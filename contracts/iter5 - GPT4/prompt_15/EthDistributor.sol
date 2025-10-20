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
        require(msg.value > 0, "No ETH sent");
        uint256 amount = msg.value / recipients.length;
        require(amount > 0, "ETH too low");
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amount);
        }
        // Any remainder stays in contract
    }

    function withdrawRemainder() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH");
        payable(owner).transfer(balance);
    }
}
