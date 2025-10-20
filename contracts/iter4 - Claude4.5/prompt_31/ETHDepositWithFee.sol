// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ETHDepositWithFee
 * @dev A contract that allows users to deposit ETH and later withdraw with a 1% fee charged to the contract owner
 */
contract ETHDepositWithFee {
    struct Deposit {
        uint256 depositId;
        address depositor;
        uint256 amount;
        uint256 timestamp;
        bool isWithdrawn;
    }
    
    address public owner;
    uint256 public feePercentage; // Fee in basis points (100 = 1%)
    uint256 public totalDeposits;
    uint256 public totalFeesCollected;
    
    mapping(address => uint256) public balances;
    mapping(address => Deposit[]) public userDeposits;
    mapping(uint256 => Deposit) public deposits;
    
    // Events
    event DepositMade(address indexed depositor, uint256 amount, uint256 depositId, uint256 timestamp);
    event WithdrawalMade(address indexed depositor, uint256 amount, uint256 fee, uint256 timestamp);
    event FeeCollected(address indexed owner, uint256 amount);
    event FeePercentageUpdated(uint256 oldFee, uint256 newFee);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
        feePercentage = 100; // 1% fee (100 basis points)
    }
    
    /**
     * @dev Allows users to deposit ETH
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        
        totalDeposits++;
        
        Deposit memory newDeposit = Deposit({
            depositId: totalDeposits,
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            isWithdrawn: false
        });
        
        deposits[totalDeposits] = newDeposit;
        userDeposits[msg.sender].push(newDeposit);
        
        emit DepositMade(msg.sender, msg.value, totalDeposits, block.timestamp);
    }
    
    /**
     * @dev Allows users to withdraw their deposited ETH with a 1% fee
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // Calculate fee (1% of withdrawal amount)
        uint256 fee = (_amount * feePercentage) / 10000;
        uint256 amountAfterFee = _amount - fee;
        
        // Update balances
        balances[msg.sender] -= _amount;
        totalFeesCollected += fee;
        
        // Transfer amount after fee to user
        payable(msg.sender).transfer(amountAfterFee);
        
        emit WithdrawalMade(msg.sender, amountAfterFee, fee, block.timestamp);
    }
    
    /**
     * @dev Allows users to withdraw all their deposited ETH with a 1% fee
     */
    function withdrawAll() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        
        // Calculate fee (1% of withdrawal amount)
        uint256 fee = (balance * feePercentage) / 10000;
        uint256 amountAfterFee = balance - fee;
        
        // Update balances
        balances[msg.sender] = 0;
        totalFeesCollected += fee;
        
        // Transfer amount after fee to user
        payable(msg.sender).transfer(amountAfterFee);
        
        emit WithdrawalMade(msg.sender, amountAfterFee, fee, block.timestamp);
    }
    
    /**
     * @dev Allows the owner to withdraw collected fees
     */
    function withdrawFees() external onlyOwner {
        require(totalFeesCollected > 0, "No fees to withdraw");
        
        uint256 feesToWithdraw = totalFeesCollected;
        totalFeesCollected = 0;
        
        payable(owner).transfer(feesToWithdraw);
        
        emit FeeCollected(owner, feesToWithdraw);
    }
    
    /**
     * @dev Allows the owner to update the fee percentage
     * @param _newFeePercentage The new fee percentage in basis points (e.g., 100 = 1%)
     */
    function updateFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 1000, "Fee cannot exceed 10%");
        
        uint256 oldFee = feePercentage;
        feePercentage = _newFeePercentage;
        
        emit FeePercentageUpdated(oldFee, _newFeePercentage);
    }
    
    /**
     * @dev Returns the balance of a user
     * @param _user The address of the user
     * @return The user's balance
     */
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    /**
     * @dev Returns the balance of the caller
     * @return The caller's balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Returns all deposits made by a user
     * @param _user The address of the user
     * @return Array of deposits
     */
    function getUserDeposits(address _user) external view returns (Deposit[] memory) {
        return userDeposits[_user];
    }
    
    /**
     * @dev Returns all deposits made by the caller
     * @return Array of deposits
     */
    function getMyDeposits() external view returns (Deposit[] memory) {
        return userDeposits[msg.sender];
    }
    
    /**
     * @dev Returns details of a specific deposit
     * @param _depositId The ID of the deposit
     * @return depositId The deposit ID
     * @return depositor The depositor's address
     * @return amount The deposit amount
     * @return timestamp When the deposit was made
     * @return isWithdrawn Whether the deposit has been withdrawn
     */
    function getDeposit(uint256 _depositId) external view returns (
        uint256 depositId,
        address depositor,
        uint256 amount,
        uint256 timestamp,
        bool isWithdrawn
    ) {
        require(_depositId > 0 && _depositId <= totalDeposits, "Invalid deposit ID");
        
        Deposit memory dep = deposits[_depositId];
        
        return (
            dep.depositId,
            dep.depositor,
            dep.amount,
            dep.timestamp,
            dep.isWithdrawn
        );
    }
    
    /**
     * @dev Calculates the fee for a given withdrawal amount
     * @param _amount The withdrawal amount
     * @return The fee amount
     */
    function calculateFee(uint256 _amount) external view returns (uint256) {
        return (_amount * feePercentage) / 10000;
    }
    
    /**
     * @dev Calculates the amount after fee for a given withdrawal amount
     * @param _amount The withdrawal amount
     * @return The amount after fee deduction
     */
    function calculateAmountAfterFee(uint256 _amount) external view returns (uint256) {
        uint256 fee = (_amount * feePercentage) / 10000;
        return _amount - fee;
    }
    
    /**
     * @dev Returns the total ETH balance of the contract
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the total number of deposits made
     * @return Total number of deposits
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
    
    /**
     * @dev Returns the total fees collected
     * @return Total fees collected
     */
    function getTotalFeesCollected() external view returns (uint256) {
        return totalFeesCollected;
    }
    
    /**
     * @dev Returns the current fee percentage
     * @return The fee percentage in basis points
     */
    function getFeePercentage() external view returns (uint256) {
        return feePercentage;
    }
    
    /**
     * @dev Returns the fee percentage as a decimal (e.g., 1.0 for 1%)
     * @return The fee percentage as a decimal * 100
     */
    function getFeePercentageDecimal() external view returns (uint256) {
        return feePercentage / 100;
    }
    
    /**
     * @dev Returns the total number of deposits made by a user
     * @param _user The address of the user
     * @return Number of deposits
     */
    function getUserDepositCount(address _user) external view returns (uint256) {
        return userDeposits[_user].length;
    }
    
    /**
     * @dev Returns the total amount deposited by a user (including withdrawn)
     * @param _user The address of the user
     * @return Total amount deposited
     */
    function getUserTotalDeposited(address _user) external view returns (uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < userDeposits[_user].length; i++) {
            total += userDeposits[_user][i].amount;
        }
        
        return total;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        
        totalDeposits++;
        
        Deposit memory newDeposit = Deposit({
            depositId: totalDeposits,
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            isWithdrawn: false
        });
        
        deposits[totalDeposits] = newDeposit;
        userDeposits[msg.sender].push(newDeposit);
        
        emit DepositMade(msg.sender, msg.value, totalDeposits, block.timestamp);
    }
}
