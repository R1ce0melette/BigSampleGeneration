// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETHDistributor {
    address public owner;

    event ETHDistributed(address[] recipients, uint256 amountPerRecipient, uint256 totalAmount);
    event ETHReceived(address indexed sender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distributeEvenly(address payable[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(address(this).balance > 0, "No ETH available for distribution");

        uint256 amountPerRecipient = address(this).balance / recipients.length;
        require(amountPerRecipient > 0, "Insufficient balance for distribution");

        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
            
            totalDistributed += amountPerRecipient;
        }

        emit ETHDistributed(recipients, amountPerRecipient, totalDistributed);
    }

    function distributeCustomAmounts(address payable[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(address(this).balance >= totalAmount, "Insufficient balance for distribution");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
        }

        emit ETHDistributed(recipients, 0, totalAmount);
    }

    function fundContract() external payable {
        require(msg.value > 0, "Must send some ETH");
        emit ETHReceived(msg.sender, msg.value);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
}
