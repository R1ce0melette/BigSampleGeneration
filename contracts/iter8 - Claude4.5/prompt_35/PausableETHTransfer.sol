// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PausableETHTransfer
 * @dev Contract that allows the owner to pause and resume ETH transfers for safety control
 */
contract PausableETHTransfer {
    // Transfer structure
    struct Transfer {
        uint256 id;
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
    uint256 private transferCounter;

    mapping(address => uint256) public balances;
    mapping(address => UserBalance) private userBalances;
    mapping(address => Transfer[]) private sentTransfers;
    mapping(address => Transfer[]) private receivedTransfers;
    
    Transfer[] private allTransfers;
    address[] private users;
    mapping(address => bool) private isUser;

    // Events
    event Paused(address indexed by, uint256 timestamp);
    event Unpaused(address indexed by, uint256 timestamp);
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event TransferExecuted(uint256 indexed transferId, address indexed from, address indexed to, uint256 amount);
    event EmergencyWithdrawal(address indexed user, uint256 amount, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
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

    modifier hasBalance(uint256 amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
        transferCounter = 0;
    }

    /**
     * @dev Pause the contract
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender, block.timestamp);
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }

    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        balances[msg.sender] += msg.value;
        userBalances[msg.sender].balance += msg.value;
        userBalances[msg.sender].totalDeposited += msg.value;

        // Track users
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw ETH from the contract
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public whenNotPaused hasBalance(amount) {
        require(amount > 0, "Withdrawal amount must be greater than 0");

        balances[msg.sender] -= amount;
        userBalances[msg.sender].balance -= amount;
        userBalances[msg.sender].totalWithdrawn += amount;

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Withdraw all balance
     */
    function withdrawAll() public whenNotPaused {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        withdraw(amount);
    }

    /**
     * @dev Transfer ETH to another address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param note Optional transfer note
     */
    function transfer(address to, uint256 amount, string memory note) 
        public 
        whenNotPaused 
        hasBalance(amount) 
        returns (uint256) 
    {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");
        require(amount > 0, "Transfer amount must be greater than 0");

        transferCounter++;
        uint256 transferId = transferCounter;

        balances[msg.sender] -= amount;
        balances[to] += amount;

        userBalances[msg.sender].balance -= amount;
        userBalances[msg.sender].totalSent += amount;
        userBalances[to].balance += amount;
        userBalances[to].totalReceived += amount;

        Transfer memory newTransfer = Transfer({
            id: transferId,
            from: msg.sender,
            to: to,
            amount: amount,
            timestamp: block.timestamp,
            note: note
        });

        sentTransfers[msg.sender].push(newTransfer);
        receivedTransfers[to].push(newTransfer);
        allTransfers.push(newTransfer);

        // Track users
        if (!isUser[to]) {
            users.push(to);
            isUser[to] = true;
        }

        emit TransferExecuted(transferId, msg.sender, to, amount);

        return transferId;
    }

    /**
     * @dev Batch transfer to multiple recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts
     * @return Array of transfer IDs
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) 
        public 
        whenNotPaused 
        returns (uint256[] memory) 
    {
        require(recipients.length > 0, "Empty recipients array");
        require(recipients.length == amounts.length, "Array length mismatch");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");

        uint256[] memory transferIds = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            transferIds[i] = transfer(recipients[i], amounts[i], "");
        }

        return transferIds;
    }

    /**
     * @dev Emergency withdrawal by owner when paused
     * @param user User address
     */
    function emergencyWithdraw(address user) public onlyOwner whenPaused {
        require(user != address(0), "Invalid user address");
        uint256 amount = balances[user];
        require(amount > 0, "No balance to withdraw");

        balances[user] = 0;
        userBalances[user].balance = 0;
        userBalances[user].totalWithdrawn += amount;

        payable(user).transfer(amount);

        emit EmergencyWithdrawal(user, amount, block.timestamp);
    }

    /**
     * @dev Get user balance details
     * @param user User address
     * @return UserBalance details
     */
    function getUserBalance(address user) public view returns (UserBalance memory) {
        return userBalances[user];
    }

    /**
     * @dev Get balance of user
     * @param user User address
     * @return Balance amount
     */
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev Get sent transfers
     * @param user User address
     * @return Array of sent transfers
     */
    function getSentTransfers(address user) public view returns (Transfer[] memory) {
        return sentTransfers[user];
    }

    /**
     * @dev Get received transfers
     * @param user User address
     * @return Array of received transfers
     */
    function getReceivedTransfers(address user) public view returns (Transfer[] memory) {
        return receivedTransfers[user];
    }

    /**
     * @dev Get all transfers
     * @return Array of all transfers
     */
    function getAllTransfers() public view returns (Transfer[] memory) {
        return allTransfers;
    }

    /**
     * @dev Get transfer by ID
     * @param transferId Transfer ID
     * @return Transfer details
     */
    function getTransfer(uint256 transferId) public view returns (Transfer memory) {
        require(transferId > 0 && transferId <= transferCounter, "Transfer does not exist");
        return allTransfers[transferId - 1];
    }

    /**
     * @dev Get all users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    /**
     * @dev Get users with balance
     * @return Array of user addresses
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
     * @dev Get total transfer count
     * @return Total number of transfers
     */
    function getTotalTransferCount() public view returns (uint256) {
        return transferCounter;
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get total value locked
     * @return Total ETH in contract
     */
    function getTotalValueLocked() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < users.length; i++) {
            total += balances[users[i]];
        }
        return total;
    }

    /**
     * @dev Get transfers by time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of transfers in time range
     */
    function getTransfersByTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Transfer[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allTransfers.length; i++) {
            if (allTransfers[i].timestamp >= startTime && allTransfers[i].timestamp <= endTime) {
                count++;
            }
        }

        Transfer[] memory result = new Transfer[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTransfers.length; i++) {
            if (allTransfers[i].timestamp >= startTime && allTransfers[i].timestamp <= endTime) {
                result[index] = allTransfers[i];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get top holders
     * @param count Number of top holders to return
     * @return Array of addresses
     */
    function getTopHolders(uint256 count) public view returns (address[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        address[] memory sortedUsers = new address[](users.length);
        
        // Copy users
        for (uint256 i = 0; i < users.length; i++) {
            sortedUsers[i] = users[i];
        }

        // Sort by balance (bubble sort)
        for (uint256 i = 0; i < sortedUsers.length; i++) {
            for (uint256 j = i + 1; j < sortedUsers.length; j++) {
                if (balances[sortedUsers[i]] < balances[sortedUsers[j]]) {
                    address temp = sortedUsers[i];
                    sortedUsers[i] = sortedUsers[j];
                    sortedUsers[j] = temp;
                }
            }
        }

        // Return top count
        uint256 resultCount = count > users.length ? users.length : count;
        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = sortedUsers[i];
        }

        return result;
    }

    /**
     * @dev Get recent transfers
     * @param count Number of recent transfers to return
     * @return Array of recent transfers
     */
    function getRecentTransfers(uint256 count) public view returns (Transfer[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > allTransfers.length ? allTransfers.length : count;
        Transfer[] memory result = new Transfer[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 index = allTransfers.length - 1 - i;
            result[i] = allTransfers[index];
        }

        return result;
    }

    /**
     * @dev Get total users count
     * @return Total number of users
     */
    function getTotalUsersCount() public view returns (uint256) {
        return users.length;
    }

    /**
     * @dev Get pause status
     * @return true if paused
     */
    function isPaused() public view returns (bool) {
        return paused;
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
     * @dev Receive function to accept ETH deposits
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
