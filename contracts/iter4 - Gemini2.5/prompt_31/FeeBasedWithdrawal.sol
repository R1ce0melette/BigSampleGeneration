// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeBasedWithdrawal {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public feePercentage = 1; // 1%

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        uint256 fee = (_amount * feePercentage) / 100;
        uint256 amountToTransfer = _amount - fee;

        balances[msg.sender] -= _amount;
        
        payable(msg.sender).transfer(amountToTransfer);
        payable(owner).transfer(fee);

        emit Withdrawn(msg.sender, amountToTransfer, fee);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
