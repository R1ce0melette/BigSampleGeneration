// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DepositWithdrawFee
 * @dev Contract that allows users to deposit ETH and withdraw with a 1% fee charged to the contract owner
 */
contract DepositWithdrawFee {
    // User balance structure
    struct UserBalance {
        uint256 totalDeposited;
        uint256 currentBalance;
        uint256 totalWithdrawn;
        uint256 totalFeePaid;
        uint256 depositCount;
        uint256 withdrawalCount;
    }

    // Deposit record
    struct DepositRecord {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    // Withdrawal record
    struct WithdrawalRecord {
        address user;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
    }

    // State variables
    address public owner;
    uint256 public feePercentage; // Fee in basis points (100 = 1%)
    uint256 public totalFeesCollected;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;

    // Mappings
    mapping(address => UserBalance) private userBalances;
    mapping(address => DepositRecord[]) private userDeposits;
    mapping(address => WithdrawalRecord[]) private userWithdrawals;
    
    address[] private users;
    mapping(address => bool) private isUser;

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee, uint256 timestamp);
    event FeeCollected(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier hasBalance() {
        require(userBalances[msg.sender].currentBalance > 0, "No balance to withdraw");
        _;
    }

    constructor() {
        owner = msg.sender;
        feePercentage = 100; // 1% = 100 basis points (out of 10000)
    }

    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Register user if first deposit
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }

        // Update user balance
        UserBalance storage userBal = userBalances[msg.sender];
        userBal.totalDeposited += msg.value;
        userBal.currentBalance += msg.value;
        userBal.depositCount++;

        // Record deposit
        userDeposits[msg.sender].push(DepositRecord({
            user: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw ETH with 1% fee
     * @param amount Amount to withdraw (before fee)
     */
    function withdraw(uint256 amount) public hasBalance {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(userBalances[msg.sender].currentBalance >= amount, "Insufficient balance");

        // Calculate fee (1%)
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        // Update user balance
        UserBalance storage userBal = userBalances[msg.sender];
        userBal.currentBalance -= amount;
        userBal.totalWithdrawn += amountAfterFee;
        userBal.totalFeePaid += fee;
        userBal.withdrawalCount++;

        // Record withdrawal
        userWithdrawals[msg.sender].push(WithdrawalRecord({
            user: msg.sender,
            amount: amountAfterFee,
            fee: fee,
            timestamp: block.timestamp
        }));

        // Update contract stats
        totalWithdrawals += amountAfterFee;
        totalFeesCollected += fee;

        // Transfer amount to user
        payable(msg.sender).transfer(amountAfterFee);

        emit Withdrawn(msg.sender, amountAfterFee, fee, block.timestamp);
    }

    /**
     * @dev Withdraw all balance with 1% fee
     */
    function withdrawAll() public hasBalance {
        uint256 amount = userBalances[msg.sender].currentBalance;
        withdraw(amount);
    }

    /**
     * @dev Owner withdraws collected fees
     * @param amount Amount of fees to withdraw
     */
    function withdrawFees(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= totalFeesCollected, "Insufficient fees collected");
        require(address(this).balance >= amount, "Insufficient contract balance");

        totalFeesCollected -= amount;
        payable(owner).transfer(amount);

        emit FeeCollected(owner, amount);
    }

    /**
     * @dev Owner withdraws all collected fees
     */
    function withdrawAllFees() public onlyOwner {
        uint256 amount = totalFeesCollected;
        require(amount > 0, "No fees to withdraw");
        
        totalFeesCollected = 0;
        payable(owner).transfer(amount);

        emit FeeCollected(owner, amount);
    }

    /**
     * @dev Update fee percentage (only owner)
     * @param newFeePercentage New fee percentage in basis points
     */
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 1000, "Fee cannot exceed 10%"); // Max 10%
        
        uint256 oldPercentage = feePercentage;
        feePercentage = newFeePercentage;

        emit FeePercentageUpdated(oldPercentage, newFeePercentage);
    }

    /**
     * @dev Transfer contract ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    // View Functions

    /**
     * @dev Get user balance
     * @param user User address
     * @return currentBalance Current withdrawable balance
     */
    function getBalance(address user) public view returns (uint256) {
        return userBalances[user].currentBalance;
    }

    /**
     * @dev Get caller's balance
     * @return Current withdrawable balance
     */
    function getMyBalance() public view returns (uint256) {
        return userBalances[msg.sender].currentBalance;
    }

    /**
     * @dev Get full user balance details
     * @param user User address
     * @return totalDeposited Total amount deposited
     * @return currentBalance Current withdrawable balance
     * @return totalWithdrawn Total amount withdrawn
     * @return totalFeePaid Total fees paid
     * @return depositCount Number of deposits
     * @return withdrawalCount Number of withdrawals
     */
    function getUserBalance(address user) 
        public 
        view 
        returns (
            uint256 totalDeposited,
            uint256 currentBalance,
            uint256 totalWithdrawn,
            uint256 totalFeePaid,
            uint256 depositCount,
            uint256 withdrawalCount
        ) 
    {
        UserBalance memory userBal = userBalances[user];
        return (
            userBal.totalDeposited,
            userBal.currentBalance,
            userBal.totalWithdrawn,
            userBal.totalFeePaid,
            userBal.depositCount,
            userBal.withdrawalCount
        );
    }

    /**
     * @dev Get user deposit history
     * @param user User address
     * @return Array of deposit records
     */
    function getUserDeposits(address user) public view returns (DepositRecord[] memory) {
        return userDeposits[user];
    }

    /**
     * @dev Get user withdrawal history
     * @param user User address
     * @return Array of withdrawal records
     */
    function getUserWithdrawals(address user) public view returns (WithdrawalRecord[] memory) {
        return userWithdrawals[user];
    }

    /**
     * @dev Get number of deposits for a user
     * @param user User address
     * @return Number of deposits
     */
    function getDepositCount(address user) public view returns (uint256) {
        return userDeposits[user].length;
    }

    /**
     * @dev Get number of withdrawals for a user
     * @param user User address
     * @return Number of withdrawals
     */
    function getWithdrawalCount(address user) public view returns (uint256) {
        return userWithdrawals[user].length;
    }

    /**
     * @dev Calculate withdrawal fee for an amount
     * @param amount Amount to withdraw
     * @return fee Fee amount
     * @return amountAfterFee Amount after fee deduction
     */
    function calculateWithdrawalFee(uint256 amount) public view returns (uint256 fee, uint256 amountAfterFee) {
        fee = (amount * feePercentage) / 10000;
        amountAfterFee = amount - fee;
        return (fee, amountAfterFee);
    }

    /**
     * @dev Get total fees collected
     * @return Total fees available for withdrawal by owner
     */
    function getCollectedFees() public view returns (uint256) {
        return totalFeesCollected;
    }

    /**
     * @dev Get contract statistics
     * @return totalDepositsAmount Total deposits
     * @return totalWithdrawalsAmount Total withdrawals
     * @return totalFeesAmount Total fees collected
     * @return totalUsers Number of users
     * @return contractBalance Contract ETH balance
     */
    function getContractStats() 
        public 
        view 
        returns (
            uint256 totalDepositsAmount,
            uint256 totalWithdrawalsAmount,
            uint256 totalFeesAmount,
            uint256 totalUsers,
            uint256 contractBalance
        ) 
    {
        return (
            totalDeposits,
            totalWithdrawals,
            totalFeesCollected,
            users.length,
            address(this).balance
        );
    }

    /**
     * @dev Get all registered users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    /**
     * @dev Get number of registered users
     * @return Number of users
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
     * @dev Get current fee percentage
     * @return Fee percentage in basis points
     */
    function getFeePercentage() public view returns (uint256) {
        return feePercentage;
    }

    /**
     * @dev Get fee percentage as decimal (e.g., 1.00 for 1%)
     * @return Fee as percentage * 100
     */
    function getFeePercentageDecimal() public view returns (uint256) {
        return feePercentage / 100;
    }

    /**
     * @dev Get users with balance
     * @return Array of addresses with non-zero balance
     */
    function getUsersWithBalance() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (userBalances[users[i]].currentBalance > 0) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (userBalances[users[i]].currentBalance > 0) {
                result[index] = users[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get top depositors
     * @param n Number of top depositors to return
     * @return addresses Array of addresses
     * @return amounts Array of total deposited amounts
     */
    function getTopDepositors(uint256 n) public view returns (address[] memory addresses, uint256[] memory amounts) {
        uint256 userCount = users.length;
        if (n > userCount) {
            n = userCount;
        }

        addresses = new address[](n);
        amounts = new uint256[](n);

        // Simple selection sort for top N
        for (uint256 i = 0; i < n; i++) {
            uint256 maxAmount = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == users[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && userBalances[users[j]].totalDeposited > maxAmount) {
                    maxAmount = userBalances[users[j]].totalDeposited;
                    maxIndex = j;
                }
            }

            if (maxAmount > 0) {
                addresses[i] = users[maxIndex];
                amounts[i] = maxAmount;
            }
        }

        return (addresses, amounts);
    }

    /**
     * @dev Check if address is a registered user
     * @param user User address
     * @return true if user has deposited before
     */
    function isRegisteredUser(address user) public view returns (bool) {
        return isUser[user];
    }

    /**
     * @dev Receive function to accept direct ETH transfers
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
