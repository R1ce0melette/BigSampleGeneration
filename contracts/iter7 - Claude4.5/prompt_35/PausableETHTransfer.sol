// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PausableETHTransfer
 * @dev Contract that allows the owner to pause and resume ETH transfers for safety control
 */
contract PausableETHTransfer {
    // Transfer record structure
    struct TransferRecord {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        string note;
    }

    // User balance structure
    struct UserBalance {
        uint256 balance;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 totalSent;
        uint256 totalReceived;
    }

    // State variables
    address public owner;
    bool public paused;
    bool public depositsEnabled;
    bool public withdrawalsEnabled;
    bool public transfersEnabled;

    // Mappings
    mapping(address => uint256) private balances;
    mapping(address => UserBalance) private userBalances;
    mapping(address => TransferRecord[]) private sentTransfers;
    mapping(address => TransferRecord[]) private receivedTransfers;
    
    TransferRecord[] private allTransfers;
    address[] private users;
    mapping(address => bool) private isUser;

    // Events
    event Paused(address indexed by, uint256 timestamp);
    event Unpaused(address indexed by, uint256 timestamp);
    event DepositsToggled(bool enabled, uint256 timestamp);
    event WithdrawalsToggled(bool enabled, uint256 timestamp);
    event TransfersToggled(bool enabled, uint256 timestamp);
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event Transferred(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EmergencyWithdrawal(address indexed owner, uint256 amount, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier whenDepositsEnabled() {
        require(depositsEnabled, "Deposits are disabled");
        _;
    }

    modifier whenWithdrawalsEnabled() {
        require(withdrawalsEnabled, "Withdrawals are disabled");
        _;
    }

    modifier whenTransfersEnabled() {
        require(transfersEnabled, "Transfers are disabled");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
        depositsEnabled = true;
        withdrawalsEnabled = true;
        transfersEnabled = true;
    }

    /**
     * @dev Pause all operations
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender, block.timestamp);
    }

    /**
     * @dev Resume all operations
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }

    /**
     * @dev Toggle deposits
     * @param enabled Enable or disable deposits
     */
    function toggleDeposits(bool enabled) public onlyOwner {
        depositsEnabled = enabled;
        emit DepositsToggled(enabled, block.timestamp);
    }

    /**
     * @dev Toggle withdrawals
     * @param enabled Enable or disable withdrawals
     */
    function toggleWithdrawals(bool enabled) public onlyOwner {
        withdrawalsEnabled = enabled;
        emit WithdrawalsToggled(enabled, block.timestamp);
    }

    /**
     * @dev Toggle transfers
     * @param enabled Enable or disable transfers
     */
    function toggleTransfers(bool enabled) public onlyOwner {
        transfersEnabled = enabled;
        emit TransfersToggled(enabled, block.timestamp);
    }

    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() public payable whenNotPaused whenDepositsEnabled {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Register user if first time
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }

        balances[msg.sender] += msg.value;
        userBalances[msg.sender].balance += msg.value;
        userBalances[msg.sender].totalDeposited += msg.value;

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw ETH from the contract
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public whenNotPaused whenWithdrawalsEnabled {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        userBalances[msg.sender].balance -= amount;
        userBalances[msg.sender].totalWithdrawn += amount;

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Withdraw all balance
     */
    function withdrawAll() public whenNotPaused whenWithdrawalsEnabled {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        withdraw(amount);
    }

    /**
     * @dev Transfer ETH to another user
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param note Optional note for the transfer
     */
    function transfer(address to, uint256 amount, string memory note) 
        public 
        whenNotPaused 
        whenTransfersEnabled 
    {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(amount > 0, "Transfer amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Register recipient if first time
        if (!isUser[to]) {
            users.push(to);
            isUser[to] = true;
        }

        balances[msg.sender] -= amount;
        balances[to] += amount;

        userBalances[msg.sender].balance -= amount;
        userBalances[msg.sender].totalSent += amount;

        userBalances[to].balance += amount;
        userBalances[to].totalReceived += amount;

        // Record transfer
        TransferRecord memory record = TransferRecord({
            from: msg.sender,
            to: to,
            amount: amount,
            timestamp: block.timestamp,
            note: note
        });

        sentTransfers[msg.sender].push(record);
        receivedTransfers[to].push(record);
        allTransfers.push(record);

        emit Transferred(msg.sender, to, amount, block.timestamp);
    }

    /**
     * @dev Transfer without note
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transfer(address to, uint256 amount) public {
        transfer(to, amount, "");
    }

    /**
     * @dev Batch transfer to multiple recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) 
        public 
        whenNotPaused 
        whenTransfersEnabled 
    {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        require(recipients.length <= 50, "Too many recipients");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(balances[msg.sender] >= totalAmount, "Insufficient balance for batch transfer");

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0) && recipients[i] != msg.sender && amounts[i] > 0) {
                transfer(recipients[i], amounts[i], "Batch transfer");
            }
        }
    }

    /**
     * @dev Emergency withdrawal by owner (when paused)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) public onlyOwner whenPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        payable(owner).transfer(amount);

        emit EmergencyWithdrawal(owner, amount, block.timestamp);
    }

    /**
     * @dev Transfer ownership
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
     * @dev Get balance of an address
     * @param account Address to check
     * @return Balance amount
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Get caller's balance
     * @return Balance amount
     */
    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @dev Get user balance details
     * @param user User address
     * @return balance Current balance
     * @return totalDeposited Total deposited
     * @return totalWithdrawn Total withdrawn
     * @return totalSent Total sent
     * @return totalReceived Total received
     */
    function getUserBalance(address user) 
        public 
        view 
        returns (
            uint256 balance,
            uint256 totalDeposited,
            uint256 totalWithdrawn,
            uint256 totalSent,
            uint256 totalReceived
        ) 
    {
        UserBalance memory userBal = userBalances[user];
        return (
            userBal.balance,
            userBal.totalDeposited,
            userBal.totalWithdrawn,
            userBal.totalSent,
            userBal.totalReceived
        );
    }

    /**
     * @dev Get sent transfers for a user
     * @param user User address
     * @return Array of transfer records
     */
    function getSentTransfers(address user) public view returns (TransferRecord[] memory) {
        return sentTransfers[user];
    }

    /**
     * @dev Get received transfers for a user
     * @param user User address
     * @return Array of transfer records
     */
    function getReceivedTransfers(address user) public view returns (TransferRecord[] memory) {
        return receivedTransfers[user];
    }

    /**
     * @dev Get all transfers
     * @return Array of all transfer records
     */
    function getAllTransfers() public view returns (TransferRecord[] memory) {
        return allTransfers;
    }

    /**
     * @dev Get total number of transfers
     * @return Total transfer count
     */
    function getTotalTransfers() public view returns (uint256) {
        return allTransfers.length;
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
     * @dev Get contract status
     * @return isPaused Contract paused status
     * @return areDepositsEnabled Deposits enabled status
     * @return areWithdrawalsEnabled Withdrawals enabled status
     * @return areTransfersEnabled Transfers enabled status
     */
    function getContractStatus() 
        public 
        view 
        returns (
            bool isPaused,
            bool areDepositsEnabled,
            bool areWithdrawalsEnabled,
            bool areTransfersEnabled
        ) 
    {
        return (paused, depositsEnabled, withdrawalsEnabled, transfersEnabled);
    }

    /**
     * @dev Get users with balance
     * @return Array of addresses with non-zero balance
     */
    function getUsersWithBalance() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (balances[users[i]] > 0) {
                count++;
            }
        }

        address[] memory result = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (balances[users[i]] > 0) {
                result[index] = users[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get top balances
     * @param n Number of top users to return
     * @return addresses Array of addresses
     * @return balanceAmounts Array of balances
     */
    function getTopBalances(uint256 n) 
        public 
        view 
        returns (address[] memory addresses, uint256[] memory balanceAmounts) 
    {
        uint256 userCount = users.length;
        if (n > userCount) {
            n = userCount;
        }

        addresses = new address[](n);
        balanceAmounts = new uint256[](n);

        // Simple selection sort for top N
        for (uint256 i = 0; i < n; i++) {
            uint256 maxBalance = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == users[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && balances[users[j]] > maxBalance) {
                    maxBalance = balances[users[j]];
                    maxIndex = j;
                }
            }

            if (maxBalance > 0) {
                addresses[i] = users[maxIndex];
                balanceAmounts[i] = maxBalance;
            }
        }

        return (addresses, balanceAmounts);
    }

    /**
     * @dev Get total deposited across all users
     * @return Total deposited amount
     */
    function getTotalDeposited() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < users.length; i++) {
            total += userBalances[users[i]].totalDeposited;
        }
        return total;
    }

    /**
     * @dev Get total withdrawn across all users
     * @return Total withdrawn amount
     */
    function getTotalWithdrawn() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < users.length; i++) {
            total += userBalances[users[i]].totalWithdrawn;
        }
        return total;
    }

    /**
     * @dev Get total transferred (internal transfers)
     * @return Total transferred amount
     */
    function getTotalTransferred() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < allTransfers.length; i++) {
            total += allTransfers[i].amount;
        }
        return total;
    }

    /**
     * @dev Check if address is a registered user
     * @param account Address to check
     * @return true if user exists
     */
    function isRegisteredUser(address account) public view returns (bool) {
        return isUser[account];
    }

    /**
     * @dev Get contract statistics
     * @return totalUsers Total number of users
     * @return totalTransfers Total number of transfers
     * @return totalDeposited Total deposited
     * @return totalWithdrawn Total withdrawn
     * @return contractBalance Contract balance
     */
    function getContractStats() 
        public 
        view 
        returns (
            uint256 totalUsers,
            uint256 totalTransfers,
            uint256 totalDeposited,
            uint256 totalWithdrawn,
            uint256 contractBalance
        ) 
    {
        return (
            users.length,
            allTransfers.length,
            getTotalDeposited(),
            getTotalWithdrawn(),
            address(this).balance
        );
    }

    /**
     * @dev Receive function to accept direct ETH transfers
     */
    receive() external payable {
        if (!paused && depositsEnabled) {
            deposit();
        } else {
            revert("Deposits are not allowed");
        }
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        if (!paused && depositsEnabled) {
            deposit();
        } else {
            revert("Deposits are not allowed");
        }
    }
}
