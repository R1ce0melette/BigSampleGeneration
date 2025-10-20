// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositWithFee {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public feesCollected;
    uint256 public constant WITHDRAWAL_FEE_PERCENT = 1;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

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

        uint256 fee = (_amount * WITHDRAWAL_FEE_PERCENT) / 100;
        uint256 amountToTransfer = _amount - fee;

        balances[msg.sender] -= _amount;
        feesCollected += fee;

        payable(msg.sender).transfer(amountToTransfer);
        
        emit Withdrawn(msg.sender, amountToTransfer, fee);
    }

    function withdrawFees() public onlyOwner {
        uint256 feesToWithdraw = feesCollected;
        require(feesToWithdraw > 0, "No fees to withdraw.");
        
        feesCollected = 0;
        payable(owner).transfer(feesToWithdraw);
        
        emit FeesWithdrawn(owner, feesToWithdraw);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
