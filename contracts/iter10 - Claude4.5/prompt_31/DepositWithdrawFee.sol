// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositWithdrawFee {
    address public owner;
    uint256 public feePercentage;
    uint256 public totalFeesCollected;

    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 newFeePercentage);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        feePercentage = 100; // 1% fee (100 basis points out of 10000)
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        deposits[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient balance");

        // Calculate fee (1% = 100 basis points out of 10000)
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        // Update balances
        deposits[msg.sender] -= amount;
        totalFeesCollected += fee;

        // Transfer amount after fee to user
        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }

    function withdrawAll() external {
        uint256 balance = deposits[msg.sender];
        require(balance > 0, "No balance to withdraw");

        // Calculate fee (1% = 100 basis points out of 10000)
        uint256 fee = (balance * feePercentage) / 10000;
        uint256 amountAfterFee = balance - fee;

        // Update balances
        deposits[msg.sender] = 0;
        totalFeesCollected += fee;

        // Transfer amount after fee to user
        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }

    function withdrawFees() external onlyOwner {
        require(totalFeesCollected > 0, "No fees to withdraw");

        uint256 feesToWithdraw = totalFeesCollected;
        totalFeesCollected = 0;

        (bool success, ) = owner.call{value: feesToWithdraw}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(owner, feesToWithdraw);
    }

    function updateFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 1000, "Fee percentage cannot exceed 10%");
        feePercentage = newFeePercentage;
        emit FeePercentageUpdated(newFeePercentage);
    }

    function getBalance(address user) external view returns (uint256) {
        return deposits[user];
    }

    function calculateWithdrawalAmount(uint256 depositAmount) external view returns (uint256 amountAfterFee, uint256 fee) {
        fee = (depositAmount * feePercentage) / 10000;
        amountAfterFee = depositAmount - fee;
        return (amountAfterFee, fee);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getFeePercentageInBasisPoints() external view returns (uint256) {
        return feePercentage;
    }

    function getFeePercentageAsDecimal() external view returns (uint256) {
        // Returns fee percentage with 2 decimal places (e.g., 100 = 1.00%)
        return feePercentage;
    }

    receive() external payable {
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
