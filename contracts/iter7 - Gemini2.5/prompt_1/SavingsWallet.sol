// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SavingsWallet
 * @dev A simple savings wallet where users can deposit and withdraw ETH.
 */
contract SavingsWallet {
    /**
     * @dev The minimum amount required for a deposit.
     */
    uint256 public constant MIN_DEPOSIT = 0.01 ether;

    /**
     * @dev Mapping from user address to their total deposited amount.
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev Emitted when a user deposits ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH withdrawn.
     */
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @dev Allows a user to deposit ETH into their savings wallet.
     * The deposited amount must be at least MIN_DEPOSIT.
     */
    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "SavingsWallet: Deposit amount is below the minimum limit.");
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their entire balance.
     */
    function withdraw() public {
        uint256 balance = _balances[msg.sender];
        require(balance > 0, "SavingsWallet: No balance to withdraw.");

        _balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "SavingsWallet: Failed to send Ether");

        emit Withdrawal(msg.sender, balance);
    }

    /**
     * @dev Returns the current balance of the calling user.
     * @return The balance of msg.sender.
     */
    function getBalance() public view returns (uint256) {
        return _balances[msg.sender];
    }
}
