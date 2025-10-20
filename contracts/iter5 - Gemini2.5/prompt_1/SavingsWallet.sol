// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SavingsWallet
 * @dev A simple savings wallet where users can deposit and withdraw ETH.
 */
contract SavingsWallet {
    // The minimum amount required for a deposit.
    uint256 public minDepositAmount;

    // Mapping from user address to their total deposited amount.
    mapping(address => uint256) public userTotalDeposits;

    /**
     * @dev Event emitted when a user deposits ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when a user withdraws ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH withdrawn.
     */
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @dev Sets the minimum deposit amount when the contract is deployed.
     * @param _minDeposit The minimum amount for a single deposit.
     */
    constructor(uint256 _minDeposit) {
        minDepositAmount = _minDeposit;
    }

    /**
     * @dev Allows a user to deposit ETH into the wallet.
     * The deposited amount must be greater than or equal to the minimum deposit amount.
     */
    function deposit() public payable {
        require(msg.value >= minDepositAmount, "Deposit amount must be greater than or equal to the minimum deposit amount.");
        userTotalDeposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw a specified amount of ETH from their balance.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 _amount) public {
        require(userTotalDeposits[msg.sender] >= _amount, "Withdrawal amount exceeds your deposited balance.");
        userTotalDeposits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    /**
     * @dev Retrieves the total deposited balance of the calling user.
     * @return The total ETH deposited by the user.
     */
    function getUserBalance() public view returns (uint256) {
        return userTotalDeposits[msg.sender];
    }

    /**
     * @dev Retrieves the total ETH balance of the contract.
     * @return The total ETH held by the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
