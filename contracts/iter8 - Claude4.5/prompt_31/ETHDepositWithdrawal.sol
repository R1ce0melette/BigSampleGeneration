// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ETHDepositWithdrawal
 * @dev Contract that allows users to deposit ETH and later withdraw with a 1% fee charged to the contract owner
 */
contract ETHDepositWithdrawal {
    // Deposit structure
    struct Deposit {
        uint256 id;
        address depositor;
        uint256 amount;
        uint256 timestamp;
    }

    // Withdrawal structure
    struct Withdrawal {
        uint256 id;
        address withdrawer;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
    }

    // User statistics
    struct UserStats {
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 totalFeesPaid;
        uint256 depositCount;
        uint256 withdrawalCount;
        uint256 currentBalance;
    }

    // State variables
    address public owner;
    uint256 public feePercentage; // in basis points (100 = 1%)
    uint256 private depositCounter;
    uint256 private withdrawalCounter;

    mapping(address => uint256) public balances;
    mapping(address => Deposit[]) private userDeposits;
    mapping(address => Withdrawal[]) private userWithdrawals;
    mapping(address => UserStats) private userStats;
    
    Deposit[] private allDeposits;
    Withdrawal[] private allWithdrawals;
    address[] private depositors;
    mapping(address => bool) private hasDeposited;

    uint256 public totalFeesCollected;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee, uint256 timestamp);
    event FeeCollected(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 newFeePercentage);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier hasBalance() {
        require(balances[msg.sender] > 0, "No balance to withdraw");
        _;
    }

    constructor() {
        owner = msg.sender;
        feePercentage = 100; // 1% fee (100 basis points)
        depositCounter = 0;
        withdrawalCounter = 0;
        totalFeesCollected = 0;
        totalDeposits = 0;
        totalWithdrawals = 0;
    }

    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        depositCounter++;

        Deposit memory newDeposit = Deposit({
            id: depositCounter,
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        userDeposits[msg.sender].push(newDeposit);
        allDeposits.push(newDeposit);

        balances[msg.sender] += msg.value;

        // Track unique depositors
        if (!hasDeposited[msg.sender]) {
            depositors.push(msg.sender);
            hasDeposited[msg.sender] = true;
        }

        // Update statistics
        userStats[msg.sender].totalDeposited += msg.value;
        userStats[msg.sender].depositCount++;
        userStats[msg.sender].currentBalance += msg.value;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw ETH from the contract with 1% fee
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public hasBalance {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        balances[msg.sender] -= amount;
        totalFeesCollected += fee;

        withdrawalCounter++;

        Withdrawal memory newWithdrawal = Withdrawal({
            id: withdrawalCounter,
            withdrawer: msg.sender,
            amount: amountAfterFee,
            fee: fee,
            timestamp: block.timestamp
        });

        userWithdrawals[msg.sender].push(newWithdrawal);
        allWithdrawals.push(newWithdrawal);

        // Update statistics
        userStats[msg.sender].totalWithdrawn += amountAfterFee;
        userStats[msg.sender].totalFeesPaid += fee;
        userStats[msg.sender].withdrawalCount++;
        userStats[msg.sender].currentBalance -= amount;
        totalWithdrawals += amountAfterFee;

        // Transfer to user
        payable(msg.sender).transfer(amountAfterFee);

        emit Withdrawn(msg.sender, amountAfterFee, fee, block.timestamp);
    }

    /**
     * @dev Withdraw all balance
     */
    function withdrawAll() public hasBalance {
        uint256 amount = balances[msg.sender];
        withdraw(amount);
    }

    /**
     * @dev Owner withdraws collected fees
     */
    function withdrawFees() public onlyOwner {
        require(totalFeesCollected > 0, "No fees to withdraw");

        uint256 feesToWithdraw = totalFeesCollected;
        totalFeesCollected = 0;

        payable(owner).transfer(feesToWithdraw);

        emit FeeCollected(owner, feesToWithdraw);
    }

    /**
     * @dev Get user balance
     * @param user User address
     * @return Balance amount
     */
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev Get user deposits
     * @param user User address
     * @return Array of deposits
     */
    function getUserDeposits(address user) public view returns (Deposit[] memory) {
        return userDeposits[user];
    }

    /**
     * @dev Get user withdrawals
     * @param user User address
     * @return Array of withdrawals
     */
    function getUserWithdrawals(address user) public view returns (Withdrawal[] memory) {
        return userWithdrawals[user];
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return UserStats details
     */
    function getUserStats(address user) public view returns (UserStats memory) {
        return userStats[user];
    }

    /**
     * @dev Get all deposits
     * @return Array of all deposits
     */
    function getAllDeposits() public view returns (Deposit[] memory) {
        return allDeposits;
    }

    /**
     * @dev Get all withdrawals
     * @return Array of all withdrawals
     */
    function getAllWithdrawals() public view returns (Withdrawal[] memory) {
        return allWithdrawals;
    }

    /**
     * @dev Get all depositors
     * @return Array of depositor addresses
     */
    function getAllDepositors() public view returns (address[] memory) {
        return depositors;
    }

    /**
     * @dev Get total deposit count
     * @return Total number of deposits
     */
    function getTotalDepositCount() public view returns (uint256) {
        return depositCounter;
    }

    /**
     * @dev Get total withdrawal count
     * @return Total number of withdrawals
     */
    function getTotalWithdrawalCount() public view returns (uint256) {
        return withdrawalCounter;
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get total users with balance
     * @return Number of users with balance
     */
    function getTotalUsersWithBalance() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            if (balances[depositors[i]] > 0) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Get users with balance
     * @return Array of user addresses
     */
    function getUsersWithBalance() public view returns (address[] memory) {
        uint256 count = getTotalUsersWithBalance();
        address[] memory result = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < depositors.length; i++) {
            if (balances[depositors[i]] > 0) {
                result[index] = depositors[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Calculate withdrawal amount after fee
     * @param amount Amount before fee
     * @return Amount after fee and fee amount
     */
    function calculateWithdrawal(uint256 amount) public view returns (uint256, uint256) {
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;
        return (amountAfterFee, fee);
    }

    /**
     * @dev Get total value locked (TVL)
     * @return Total value locked
     */
    function getTotalValueLocked() public view returns (uint256) {
        return totalDeposits - totalWithdrawals - totalFeesCollected;
    }

    /**
     * @dev Update fee percentage
     * @param newFeePercentage New fee percentage in basis points
     */
    function updateFeePercentage(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 1000, "Fee cannot exceed 10%");
        feePercentage = newFeePercentage;

        emit FeePercentageUpdated(newFeePercentage);
    }

    /**
     * @dev Get top depositors by balance
     * @param count Number of top depositors to return
     * @return Array of addresses
     */
    function getTopDepositors(uint256 count) public view returns (address[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > depositors.length ? depositors.length : count;
        address[] memory sortedDepositors = new address[](depositors.length);
        
        // Copy depositors
        for (uint256 i = 0; i < depositors.length; i++) {
            sortedDepositors[i] = depositors[i];
        }

        // Sort by balance (bubble sort for simplicity)
        for (uint256 i = 0; i < sortedDepositors.length; i++) {
            for (uint256 j = i + 1; j < sortedDepositors.length; j++) {
                if (balances[sortedDepositors[i]] < balances[sortedDepositors[j]]) {
                    address temp = sortedDepositors[i];
                    sortedDepositors[i] = sortedDepositors[j];
                    sortedDepositors[j] = temp;
                }
            }
        }

        // Return top count
        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = sortedDepositors[i];
        }

        return result;
    }

    /**
     * @dev Get deposit history for time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of deposits in time range
     */
    function getDepositsByTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Deposit[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allDeposits.length; i++) {
            if (allDeposits[i].timestamp >= startTime && allDeposits[i].timestamp <= endTime) {
                count++;
            }
        }

        Deposit[] memory result = new Deposit[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allDeposits.length; i++) {
            if (allDeposits[i].timestamp >= startTime && allDeposits[i].timestamp <= endTime) {
                result[index] = allDeposits[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get withdrawal history for time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of withdrawals in time range
     */
    function getWithdrawalsByTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Withdrawal[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allWithdrawals.length; i++) {
            if (allWithdrawals[i].timestamp >= startTime && allWithdrawals[i].timestamp <= endTime) {
                count++;
            }
        }

        Withdrawal[] memory result = new Withdrawal[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allWithdrawals.length; i++) {
            if (allWithdrawals[i].timestamp >= startTime && allWithdrawals[i].timestamp <= endTime) {
                result[index] = allWithdrawals[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
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
