// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PausableETHTransfer
 * @dev A contract that allows the owner to pause and resume ETH transfers for safety control
 */
contract PausableETHTransfer {
    struct Transfer {
        uint256 transferId;
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        bool isCompleted;
    }
    
    struct Account {
        address accountAddress;
        uint256 balance;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 totalSent;
        uint256 totalReceived;
    }
    
    address public owner;
    bool public isPaused;
    uint256 public totalTransfers;
    uint256 public totalDeposits;
    
    mapping(address => Account) public accounts;
    mapping(uint256 => Transfer) public transfers;
    mapping(address => uint256[]) public userTransfersFrom;
    mapping(address => uint256[]) public userTransfersTo;
    
    // Events
    event Paused(address indexed owner, uint256 timestamp);
    event Unpaused(address indexed owner, uint256 timestamp);
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event TransferMade(uint256 indexed transferId, address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(isPaused, "Contract is not paused");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
        isPaused = false;
    }
    
    /**
     * @dev Pauses all ETH transfers
     */
    function pause() external onlyOwner whenNotPaused {
        isPaused = true;
        emit Paused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Resumes all ETH transfers
     */
    function unpause() external onlyOwner whenPaused {
        isPaused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Deposits ETH into the contract
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        accounts[msg.sender].accountAddress = msg.sender;
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].totalDeposited += msg.value;
        
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraws ETH from the contract
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(accounts[msg.sender].balance >= _amount, "Insufficient balance");
        
        accounts[msg.sender].balance -= _amount;
        accounts[msg.sender].totalWithdrawn += _amount;
        
        payable(msg.sender).transfer(_amount);
        
        emit Withdrawn(msg.sender, _amount, block.timestamp);
    }
    
    /**
     * @dev Withdraws all ETH from the contract
     */
    function withdrawAll() external whenNotPaused {
        uint256 balance = accounts[msg.sender].balance;
        require(balance > 0, "No balance to withdraw");
        
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].totalWithdrawn += balance;
        
        payable(msg.sender).transfer(balance);
        
        emit Withdrawn(msg.sender, balance, block.timestamp);
    }
    
    /**
     * @dev Transfers ETH to another address within the contract
     * @param _to The recipient's address
     * @param _amount The amount to transfer
     */
    function transfer(address _to, uint256 _amount) external whenNotPaused returns (uint256) {
        require(_to != address(0), "Invalid recipient address");
        require(_to != msg.sender, "Cannot transfer to yourself");
        require(_amount > 0, "Transfer amount must be greater than 0");
        require(accounts[msg.sender].balance >= _amount, "Insufficient balance");
        
        // Update balances
        accounts[msg.sender].balance -= _amount;
        accounts[msg.sender].totalSent += _amount;
        
        accounts[_to].accountAddress = _to;
        accounts[_to].balance += _amount;
        accounts[_to].totalReceived += _amount;
        
        // Record transfer
        totalTransfers++;
        uint256 transferId = totalTransfers;
        
        transfers[transferId] = Transfer({
            transferId: transferId,
            from: msg.sender,
            to: _to,
            amount: _amount,
            timestamp: block.timestamp,
            isCompleted: true
        });
        
        userTransfersFrom[msg.sender].push(transferId);
        userTransfersTo[_to].push(transferId);
        
        emit TransferMade(transferId, msg.sender, _to, _amount, block.timestamp);
        
        return transferId;
    }
    
    /**
     * @dev Emergency withdraw by owner (only when paused)
     * @param _to The address to send funds to
     * @param _amount The amount to withdraw
     */
    function emergencyWithdraw(address _to, uint256 _amount) external onlyOwner whenPaused {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        payable(_to).transfer(_amount);
    }
    
    /**
     * @dev Returns account details
     * @param _account The address of the account
     * @return accountAddress The account address
     * @return balance The current balance
     * @return totalDeposited Total amount deposited
     * @return totalWithdrawn Total amount withdrawn
     * @return totalSent Total amount sent
     * @return totalReceived Total amount received
     */
    function getAccount(address _account) external view returns (
        address accountAddress,
        uint256 balance,
        uint256 totalDeposited,
        uint256 totalWithdrawn,
        uint256 totalSent,
        uint256 totalReceived
    ) {
        Account memory account = accounts[_account];
        
        return (
            account.accountAddress,
            account.balance,
            account.totalDeposited,
            account.totalWithdrawn,
            account.totalSent,
            account.totalReceived
        );
    }
    
    /**
     * @dev Returns transfer details
     * @param _transferId The ID of the transfer
     * @return transferId The transfer ID
     * @return from The sender's address
     * @return to The recipient's address
     * @return amount The transfer amount
     * @return timestamp When the transfer occurred
     * @return isCompleted Whether the transfer is completed
     */
    function getTransfer(uint256 _transferId) external view returns (
        uint256 transferId,
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        bool isCompleted
    ) {
        require(_transferId > 0 && _transferId <= totalTransfers, "Invalid transfer ID");
        
        Transfer memory t = transfers[_transferId];
        
        return (
            t.transferId,
            t.from,
            t.to,
            t.amount,
            t.timestamp,
            t.isCompleted
        );
    }
    
    /**
     * @dev Returns the balance of an account
     * @param _account The address of the account
     * @return The account balance
     */
    function getBalance(address _account) external view returns (uint256) {
        return accounts[_account].balance;
    }
    
    /**
     * @dev Returns the caller's balance
     * @return The caller's balance
     */
    function getMyBalance() external view returns (uint256) {
        return accounts[msg.sender].balance;
    }
    
    /**
     * @dev Returns all transfers sent by an account
     * @param _account The address of the account
     * @return Array of transfer IDs
     */
    function getTransfersFrom(address _account) external view returns (uint256[] memory) {
        return userTransfersFrom[_account];
    }
    
    /**
     * @dev Returns all transfers received by an account
     * @param _account The address of the account
     * @return Array of transfer IDs
     */
    function getTransfersTo(address _account) external view returns (uint256[] memory) {
        return userTransfersTo[_account];
    }
    
    /**
     * @dev Returns all transfers sent by the caller
     * @return Array of transfer IDs
     */
    function getMyTransfersFrom() external view returns (uint256[] memory) {
        return userTransfersFrom[msg.sender];
    }
    
    /**
     * @dev Returns all transfers received by the caller
     * @return Array of transfer IDs
     */
    function getMyTransfersTo() external view returns (uint256[] memory) {
        return userTransfersTo[msg.sender];
    }
    
    /**
     * @dev Returns the pause status
     * @return True if paused, false otherwise
     */
    function getPauseStatus() external view returns (bool) {
        return isPaused;
    }
    
    /**
     * @dev Returns the total number of transfers
     * @return Total number of transfers
     */
    function getTotalTransfers() external view returns (uint256) {
        return totalTransfers;
    }
    
    /**
     * @dev Returns the total deposits made
     * @return Total deposits
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    /**
     * @dev Returns the contract balance
     * @return Contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the caller's account details
     * @return accountAddress The account address
     * @return balance The current balance
     * @return totalDeposited Total amount deposited
     * @return totalWithdrawn Total amount withdrawn
     * @return totalSent Total amount sent
     * @return totalReceived Total amount received
     */
    function getMyAccount() external view returns (
        address accountAddress,
        uint256 balance,
        uint256 totalDeposited,
        uint256 totalWithdrawn,
        uint256 totalSent,
        uint256 totalReceived
    ) {
        Account memory account = accounts[msg.sender];
        
        return (
            account.accountAddress,
            account.balance,
            account.totalDeposited,
            account.totalWithdrawn,
            account.totalSent,
            account.totalReceived
        );
    }
    
    /**
     * @dev Batch transfers to multiple recipients
     * @param _recipients Array of recipient addresses
     * @param _amounts Array of amounts to transfer
     */
    function batchTransfer(address[] memory _recipients, uint256[] memory _amounts) external whenNotPaused {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        
        uint256 totalAmount = 0;
        
        // Calculate total amount needed
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            require(_recipients[i] != msg.sender, "Cannot transfer to yourself");
            require(_amounts[i] > 0, "Transfer amount must be greater than 0");
            totalAmount += _amounts[i];
        }
        
        require(accounts[msg.sender].balance >= totalAmount, "Insufficient balance");
        
        // Perform transfers
        for (uint256 i = 0; i < _recipients.length; i++) {
            accounts[msg.sender].balance -= _amounts[i];
            accounts[msg.sender].totalSent += _amounts[i];
            
            accounts[_recipients[i]].accountAddress = _recipients[i];
            accounts[_recipients[i]].balance += _amounts[i];
            accounts[_recipients[i]].totalReceived += _amounts[i];
            
            totalTransfers++;
            uint256 transferId = totalTransfers;
            
            transfers[transferId] = Transfer({
                transferId: transferId,
                from: msg.sender,
                to: _recipients[i],
                amount: _amounts[i],
                timestamp: block.timestamp,
                isCompleted: true
            });
            
            userTransfersFrom[msg.sender].push(transferId);
            userTransfersTo[_recipients[i]].push(transferId);
            
            emit TransferMade(transferId, msg.sender, _recipients[i], _amounts[i], block.timestamp);
        }
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        accounts[msg.sender].accountAddress = msg.sender;
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].totalDeposited += msg.value;
        
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
}
