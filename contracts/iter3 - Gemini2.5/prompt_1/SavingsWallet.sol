// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SavingsWallet
 * @dev A simple savings wallet where users can deposit and withdraw ETH.
 */
contract SavingsWallet {
    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;

    mapping(address => uint256) public userBalances;

    /**
     * @dev Emitted when a user deposits ETH.
     * @param user The address of the user.
     * @param amount The amount deposited.
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH.
     * @param user The address of the user.
     * @param amount The amount withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Allows a user to deposit ETH into their savings wallet.
     * The deposited amount must be at least the minimum deposit limit.
     */
    function deposit() public payable {
        require(msg.value >= MINIMUM_DEPOSIT, "SavingsWallet: Deposit amount is below the minimum limit.");
        userBalances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw a specific amount of ETH from their savings wallet.
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 amount) public {
        require(userBalances[msg.sender] >= amount, "SavingsWallet: Insufficient balance for withdrawal.");
        userBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Retrieves the total balance of a specific user.
     * @param user The address of the user.
     * @return The total balance of the user.
     */
    function getTotalDeposits(address user) public view returns (uint256) {
        return userBalances[user];
    }

    /**
     * @dev Retrieves the total balance of the contract.
     * @return The total balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
