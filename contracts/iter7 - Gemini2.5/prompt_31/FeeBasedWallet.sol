// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeeBasedWallet
 * @dev A wallet that allows users to deposit and withdraw ETH, with a 1% fee on withdrawals
 * that is collected by the contract owner.
 */
contract FeeBasedWallet {
    // The address of the contract owner who will receive the fees.
    address public owner;

    // Mapping from user address to their balance.
    mapping(address => uint256) public balances;

    /**
     * @dev Emitted when a user deposits ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH deposited.
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH withdrawn by the user.
     * @param fee The fee collected by the owner.
     */
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);

    /**
     * @dev Sets the contract owner to the deployer's address.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows a user to deposit ETH into their wallet.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw a specific amount from their balance.
     * A 1% fee is charged on the withdrawal amount and sent to the owner.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        uint256 fee = (_amount * 1) / 100;
        uint256 amountToUser = _amount - fee;

        balances[msg.sender] -= _amount;

        // Send the fee to the owner.
        (bool feeSuccess, ) = payable(owner).call{value: fee}("");
        require(feeSuccess, "Failed to send fee to owner.");

        // Send the remaining amount to the user.
        (bool userSuccess, ) = payable(msg.sender).call{value: amountToUser}("");
        require(userSuccess, "Failed to send funds to user.");

        emit Withdrawn(msg.sender, amountToUser, fee);
    }

    /**
     * @dev Returns the current balance of the calling user.
     * @return The balance of msg.sender.
     */
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
