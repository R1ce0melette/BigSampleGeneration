// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeBasedWallet is Ownable {
    mapping(address => uint256) public balances;
    uint256 public totalFeesCollected;
    uint256 public constant WITHDRAWAL_FEE_PERCENT = 1;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Allows users to deposit ETH into their account.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw their ETH, subject to a 1% fee.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        uint256 fee = (_amount * WITHDRAWAL_FEE_PERCENT) / 100;
        uint256 amountToTransfer = _amount - fee;

        balances[msg.sender] -= _amount;
        totalFeesCollected += fee;

        payable(msg.sender).transfer(amountToTransfer);
        emit Withdrawn(msg.sender, amountToTransfer, fee);
    }

    /**
     * @dev Allows the contract owner to withdraw the accumulated fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 feesToWithdraw = totalFeesCollected;
        require(feesToWithdraw > 0, "No fees to withdraw.");
        
        totalFeesCollected = 0;
        
        emit FeesWithdrawn(owner(), feesToWithdraw);
        payable(owner()).transfer(feesToWithdraw);
    }

    /**
     * @dev Returns the balance of the calling user.
     */
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
