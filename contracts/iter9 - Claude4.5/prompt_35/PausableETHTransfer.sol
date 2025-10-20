// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableETHTransfer {
    address public owner;
    bool public isPaused;
    
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    
    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event TransferExecuted(address indexed from, address indexed to, uint256 amount);
    event Paused(address indexed by, uint256 timestamp);
    event Unpaused(address indexed by, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
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
    
    constructor() {
        owner = msg.sender;
        isPaused = false;
    }
    
    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner whenNotPaused {
        isPaused = true;
        emit Paused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Resume the contract
     */
    function unpause() external onlyOwner whenPaused {
        isPaused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Deposit ETH into the contract
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Receive ETH directly
     */
    receive() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw ETH from the contract
     * @param _amount Amount to withdraw
     */
    function withdraw(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        totalWithdrawals += _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Withdraw all balance
     */
    function withdrawAll() external whenNotPaused {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        totalWithdrawals += balance;
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, balance);
    }
    
    /**
     * @dev Transfer ETH to another address within the contract
     * @param _to Recipient address
     * @param _amount Amount to transfer
     */
    function transfer(address _to, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        emit TransferExecuted(msg.sender, _to, _amount);
    }
    
    /**
     * @dev Send ETH directly to an external address
     * @param _to Recipient address
     * @param _amount Amount to send
     */
    function sendETH(address payable _to, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        totalWithdrawals += _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit TransferExecuted(msg.sender, _to, _amount);
    }
    
    /**
     * @dev Get user balance
     * @param _user User address
     */
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get contract status
     */
    function getStatus() external view returns (
        bool _isPaused,
        uint256 _totalDeposits,
        uint256 _totalWithdrawals,
        uint256 _contractBalance
    ) {
        return (
            isPaused,
            totalDeposits,
            totalWithdrawals,
            address(this).balance
        );
    }
    
    /**
     * @dev Emergency withdrawal by owner (can be used even when paused)
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdrawal(owner, _amount);
    }
    
    /**
     * @dev Emergency withdrawal of all funds by owner (can be used even when paused)
     */
    function emergencyWithdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdrawal(owner, balance);
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
    /**
     * @dev Check if contract is currently paused
     */
    function paused() external view returns (bool) {
        return isPaused;
    }
}
