// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SavingsWallet
 * @dev A simple savings wallet where users can deposit and withdraw ETH.
 * It enforces a minimum deposit amount and tracks each user's total deposits.
 */
contract SavingsWallet {
    /**
     * @dev The minimum amount in wei required for a deposit.
     */
    uint256 public constant MIN_DEPOSIT = 0.01 ether;

    /**
     * @dev Mapping from a user's address to their total deposited amount.
     */
    mapping(address => uint256) private _totalDeposits;

    /**
     * @dev Emitted when a user successfully deposits ETH.
     * @param user The address of the user who deposited.
     * @param amount The amount of ETH deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user successfully withdraws ETH.
     * @param user The address of the user who withdrew.
     * @param amount The amount of ETH withdrawn.
     */
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @dev Allows a user to deposit ETH into their savings wallet.
     * The amount must be equal to or greater than the `MIN_DEPOSIT`.
     */
    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit amount is below the minimum limit.");
        _totalDeposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their entire balance from the contract.
     */
    function withdraw() public {
        uint256 balance = _totalDeposits[msg.sender];
        require(balance > 0, "No balance to withdraw.");

        _totalDeposits[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether upon withdrawal.");

        emit Withdrawal(msg.sender, balance);
    }

    /**
     * @dev Returns the total amount of ETH deposited by the calling user.
     * @return The total deposited balance of `msg.sender`.
     */
    function getTotalDeposit() public view returns (uint256) {
        return _totalDeposits[msg.sender];
    }
}
