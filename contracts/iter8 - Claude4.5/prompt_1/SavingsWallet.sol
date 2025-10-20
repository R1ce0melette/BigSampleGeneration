// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SavingsWallet
 * @dev Savings wallet where users can deposit and withdraw ETH with minimum deposit limit
 */
contract SavingsWallet {
    // Minimum deposit amount
    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;

    // State variables
    mapping(address => uint256) private balances;
    mapping(address => uint256) private totalDeposits;
    mapping(address => uint256) private depositCount;
    mapping(address => uint256) private withdrawalCount;
    
    address[] private users;
    mapping(address => bool) private isUser;

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);

    /**
     * @dev Deposit ETH into the savings wallet
     */
    function deposit() public payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit amount must be at least 0.01 ETH");

        // Register user if first deposit
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }

        balances[msg.sender] += msg.value;
        totalDeposits[msg.sender] += msg.value;
        depositCount[msg.sender]++;

        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw ETH from the savings wallet
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        withdrawalCount[msg.sender]++;

        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Withdraw all balance
     */
    function withdrawAll() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        withdraw(amount);
    }

    /**
     * @dev Get balance of caller
     * @return Current balance
     */
    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @dev Get total deposits of caller
     * @return Total deposits
     */
    function getMyTotalDeposits() public view returns (uint256) {
        return totalDeposits[msg.sender];
    }

    /**
     * @dev Get balance of a user
     * @param user User address
     * @return Balance amount
     */
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev Get total deposits of a user
     * @param user User address
     * @return Total deposits
     */
    function getTotalDeposits(address user) public view returns (uint256) {
        return totalDeposits[user];
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return balance Current balance
     * @return totalDeposited Total deposits
     * @return numDeposits Number of deposits
     * @return numWithdrawals Number of withdrawals
     */
    function getUserStats(address user) 
        public 
        view 
        returns (
            uint256 balance,
            uint256 totalDeposited,
            uint256 numDeposits,
            uint256 numWithdrawals
        ) 
    {
        return (
            balances[user],
            totalDeposits[user],
            depositCount[user],
            withdrawalCount[user]
        );
    }

    /**
     * @dev Get all users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    /**
     * @dev Get total number of users
     * @return Total user count
     */
    function getTotalUsers() public view returns (uint256) {
        return users.length;
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        deposit();
    }
}
