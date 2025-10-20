// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositWithdrawalVault {
    address public owner;
    uint256 public feePercentage = 1; // 1% fee
    uint256 public constant PERCENTAGE_BASE = 100;
    
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    uint256 public totalFees;
    
    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeeCollected(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Deposit ETH into the vault
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Receive ETH directly
     */
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw ETH from the vault (with fee)
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Calculate fee
        uint256 fee = (_amount * feePercentage) / PERCENTAGE_BASE;
        uint256 amountAfterFee = _amount - fee;
        
        // Update balance and fees
        balances[msg.sender] -= _amount;
        totalFees += fee;
        
        // Transfer amount after fee to user
        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }
    
    /**
     * @dev Withdraw all balance (with fee)
     */
    function withdrawAll() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        
        // Calculate fee
        uint256 fee = (balance * feePercentage) / PERCENTAGE_BASE;
        uint256 amountAfterFee = balance - fee;
        
        // Update balance and fees
        balances[msg.sender] = 0;
        totalFees += fee;
        
        // Transfer amount after fee to user
        (bool success, ) = msg.sender.call{value: amountAfterFee}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }
    
    /**
     * @dev Owner collects accumulated fees
     */
    function collectFees() external onlyOwner {
        require(totalFees > 0, "No fees to collect");
        
        uint256 feeAmount = totalFees;
        totalFees = 0;
        
        (bool success, ) = owner.call{value: feeAmount}("");
        require(success, "Transfer failed");
        
        emit FeeCollected(owner, feeAmount);
    }
    
    /**
     * @dev Owner updates the fee percentage
     * @param _newFeePercentage The new fee percentage (0-100)
     */
    function updateFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 10, "Fee percentage cannot exceed 10%");
        
        uint256 oldPercentage = feePercentage;
        feePercentage = _newFeePercentage;
        
        emit FeePercentageUpdated(oldPercentage, _newFeePercentage);
    }
    
    /**
     * @dev Get user balance
     * @param _user The user address
     * @return The user's balance
     */
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    /**
     * @dev Calculate withdrawal amount after fee
     * @param _amount The amount to withdraw
     * @return amountAfterFee The amount user will receive
     * @return fee The fee amount
     */
    function calculateWithdrawal(uint256 _amount) external view returns (
        uint256 amountAfterFee,
        uint256 fee
    ) {
        fee = (_amount * feePercentage) / PERCENTAGE_BASE;
        amountAfterFee = _amount - fee;
        
        return (amountAfterFee, fee);
    }
    
    /**
     * @dev Get contract statistics
     * @return _totalDeposits Total deposits made
     * @return _totalFees Total fees collected
     * @return _contractBalance Current contract balance
     * @return _feePercentage Current fee percentage
     */
    function getStatistics() external view returns (
        uint256 _totalDeposits,
        uint256 _totalFees,
        uint256 _contractBalance,
        uint256 _feePercentage
    ) {
        return (
            totalDeposits,
            totalFees,
            address(this).balance,
            feePercentage
        );
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param _newOwner The new owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        
        owner = _newOwner;
    }
}
