// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenFaucet
 * @dev A token faucet that lets users claim a small fixed amount of tokens once every 24 hours
 */
contract TokenFaucet {
    address public owner;
    uint256 public claimAmount;
    uint256 public claimInterval;
    
    // Mapping to track last claim time for each user
    mapping(address => uint256) public lastClaimTime;
    
    // Mapping to track total claimed by each user
    mapping(address => uint256) public totalClaimed;
    
    // Mapping to track user balances
    mapping(address => uint256) public balances;
    
    uint256 public totalDistributed;
    
    // Events
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetFunded(address indexed funder, uint256 amount);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event ClaimIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event TokensWithdrawn(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the faucet
     * @param _claimAmount The amount of tokens (wei) users can claim per interval
     */
    constructor(uint256 _claimAmount) {
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        
        owner = msg.sender;
        claimAmount = _claimAmount;
        claimInterval = 24 hours;
    }
    
    /**
     * @dev Allows users to claim tokens from the faucet
     */
    function claimTokens() external {
        require(canClaim(msg.sender), "Cannot claim yet, please wait for the claim interval to pass");
        require(address(this).balance >= claimAmount, "Faucet is empty, please try again later");
        
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += claimAmount;
        balances[msg.sender] += claimAmount;
        totalDistributed += claimAmount;
        
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
    
    /**
     * @dev Checks if a user can claim tokens
     * @param _user The address of the user
     * @return True if the user can claim, false otherwise
     */
    function canClaim(address _user) public view returns (bool) {
        if (lastClaimTime[_user] == 0) {
            return true;
        }
        return block.timestamp >= lastClaimTime[_user] + claimInterval;
    }
    
    /**
     * @dev Returns the time remaining until the user can claim again
     * @param _user The address of the user
     * @return Time remaining in seconds, or 0 if can claim now
     */
    function getTimeUntilNextClaim(address _user) external view returns (uint256) {
        if (lastClaimTime[_user] == 0) {
            return 0;
        }
        
        uint256 nextClaimTime = lastClaimTime[_user] + claimInterval;
        
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }
        
        return nextClaimTime - block.timestamp;
    }
    
    /**
     * @dev Allows users to withdraw their claimed tokens
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit TokensWithdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Allows users to withdraw all their claimed tokens
     */
    function withdrawAll() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit TokensWithdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Allows anyone to fund the faucet
     */
    function fundFaucet() external payable {
        require(msg.value > 0, "Must send ETH to fund faucet");
        
        emit FaucetFunded(msg.sender, msg.value);
    }
    
    /**
     * @dev Allows the owner to update the claim amount
     * @param _newAmount The new claim amount
     */
    function updateClaimAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Claim amount must be greater than 0");
        
        uint256 oldAmount = claimAmount;
        claimAmount = _newAmount;
        
        emit ClaimAmountUpdated(oldAmount, _newAmount);
    }
    
    /**
     * @dev Allows the owner to update the claim interval
     * @param _newInterval The new claim interval in seconds
     */
    function updateClaimInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval > 0, "Claim interval must be greater than 0");
        
        uint256 oldInterval = claimInterval;
        claimInterval = _newInterval;
        
        emit ClaimIntervalUpdated(oldInterval, _newInterval);
    }
    
    /**
     * @dev Returns the user's balance in the faucet
     * @param _user The address of the user
     * @return The user's balance
     */
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    /**
     * @dev Returns the caller's balance
     * @return The caller's balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Returns the total amount claimed by a user
     * @param _user The address of the user
     * @return The total claimed amount
     */
    function getTotalClaimed(address _user) external view returns (uint256) {
        return totalClaimed[_user];
    }
    
    /**
     * @dev Returns the last claim time for a user
     * @param _user The address of the user
     * @return The last claim timestamp
     */
    function getLastClaimTime(address _user) external view returns (uint256) {
        return lastClaimTime[_user];
    }
    
    /**
     * @dev Returns the faucet balance
     * @return The faucet balance
     */
    function getFaucetBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns comprehensive user information
     * @param _user The address of the user
     * @return balance User's withdrawable balance
     * @return claimed Total amount claimed
     * @return lastClaim Last claim timestamp
     * @return canClaimNow Whether user can claim now
     */
    function getUserInfo(address _user) external view returns (
        uint256 balance,
        uint256 claimed,
        uint256 lastClaim,
        bool canClaimNow
    ) {
        return (
            balances[_user],
            totalClaimed[_user],
            lastClaimTime[_user],
            canClaim(_user)
        );
    }
    
    /**
     * @dev Transfers ownership of the faucet
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {
        emit FaucetFunded(msg.sender, msg.value);
    }
}
