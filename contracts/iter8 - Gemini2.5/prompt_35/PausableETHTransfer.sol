// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PausableETHTransfer
 * @dev A contract that demonstrates a pausable mechanism for ETH transfers.
 * The owner can pause and unpause the contract's core functionalities like deposits and withdrawals.
 */
contract PausableETHTransfer {
    address public owner;
    bool public paused;

    mapping(address => uint256) public balances;

    event Paused(address account);
    event Unpaused(address account);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    /**
     * @dev Pauses the contract's transfer functionalities.
     * Can only be called by the owner.
     */
    function pause() external onlyOwner {
        require(!paused, "Contract is already paused.");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Resumes the contract's transfer functionalities.
     * Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        require(paused, "Contract is not paused.");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows users to deposit ETH into their balance.
     * This function is affected by the paused state.
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw a specified amount from their balance.
     * This function is affected by the paused state.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        balances[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed.");

        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to withdraw the entire contract balance in an emergency.
     * This function bypasses the paused state for safety.
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "No funds to withdraw.");

        (bool success, ) = payable(owner).call{value: totalBalance}("");
        require(success, "Emergency withdrawal failed.");
        
        emit EmergencyWithdrawal(owner, totalBalance);
    }

    /**
     * @dev Fallback function to receive ETH deposits.
     */
    receive() external payable {
        deposit();
    }
}
