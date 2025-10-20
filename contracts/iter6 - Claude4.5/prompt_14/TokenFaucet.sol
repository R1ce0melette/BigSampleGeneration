// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenFaucet
 * @dev A token faucet that lets users claim a small fixed amount of tokens once every 24 hours
 */
contract TokenFaucet {
    address public owner;
    uint256 public claimAmount;
    uint256 public constant CLAIM_INTERVAL = 24 hours;
    
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public totalClaimed;
    mapping(address => uint256) public claimCount;
    
    uint256 public totalDistributed;
    uint256 public totalClaims;
    
    // Events
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetFunded(address indexed funder, uint256 amount);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor(uint256 _claimAmount) payable {
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        owner = msg.sender;
        claimAmount = _claimAmount;
    }
    
    /**
     * @dev Claim tokens from the faucet
     */
    function claimTokens() external {
        require(canClaim(msg.sender), "Cannot claim yet, please wait for the claim interval");
        require(address(this).balance >= claimAmount, "Faucet is empty");
        
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += claimAmount;
        claimCount[msg.sender]++;
        totalDistributed += claimAmount;
        totalClaims++;
        
        (bool success, ) = msg.sender.call{value: claimAmount}("");
        require(success, "Transfer failed");
        
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
    
    /**
     * @dev Check if a user can claim tokens
     * @param user The address to check
     * @return True if the user can claim, false otherwise
     */
    function canClaim(address user) public view returns (bool) {
        if (lastClaimTime[user] == 0) {
            return true;
        }
        return block.timestamp >= lastClaimTime[user] + CLAIM_INTERVAL;
    }
    
    /**
     * @dev Get time remaining until next claim
     * @param user The address to check
     * @return The time remaining in seconds, or 0 if can claim now
     */
    function getTimeUntilNextClaim(address user) external view returns (uint256) {
        if (canClaim(user)) {
            return 0;
        }
        uint256 nextClaimTime = lastClaimTime[user] + CLAIM_INTERVAL;
        return nextClaimTime - block.timestamp;
    }
    
    /**
     * @dev Get user claim information
     * @param user The address to query
     * @return _totalClaimed Total amount claimed by user
     * @return _claimCount Number of times user has claimed
     * @return _lastClaimTime Timestamp of last claim
     * @return _canClaimNow Whether user can claim now
     */
    function getUserInfo(address user) external view returns (
        uint256 _totalClaimed,
        uint256 _claimCount,
        uint256 _lastClaimTime,
        bool _canClaimNow
    ) {
        return (
            totalClaimed[user],
            claimCount[user],
            lastClaimTime[user],
            canClaim(user)
        );
    }
    
    /**
     * @dev Get the caller's claim information
     * @return _totalClaimed Total amount claimed
     * @return _claimCount Number of times claimed
     * @return _lastClaimTime Timestamp of last claim
     * @return _canClaimNow Whether can claim now
     * @return _timeUntilNextClaim Time until next claim
     */
    function getMyInfo() external view returns (
        uint256 _totalClaimed,
        uint256 _claimCount,
        uint256 _lastClaimTime,
        bool _canClaimNow,
        uint256 _timeUntilNextClaim
    ) {
        bool canClaimNow = canClaim(msg.sender);
        uint256 timeUntilNext = 0;
        
        if (!canClaimNow) {
            uint256 nextClaimTime = lastClaimTime[msg.sender] + CLAIM_INTERVAL;
            timeUntilNext = nextClaimTime - block.timestamp;
        }
        
        return (
            totalClaimed[msg.sender],
            claimCount[msg.sender],
            lastClaimTime[msg.sender],
            canClaimNow,
            timeUntilNext
        );
    }
    
    /**
     * @dev Fund the faucet with tokens
     */
    function fundFaucet() external payable {
        require(msg.value > 0, "Must send some ETH");
        emit FaucetFunded(msg.sender, msg.value);
    }
    
    /**
     * @dev Update the claim amount (owner only)
     * @param newAmount The new claim amount
     */
    function updateClaimAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Claim amount must be greater than 0");
        
        uint256 oldAmount = claimAmount;
        claimAmount = newAmount;
        
        emit ClaimAmountUpdated(oldAmount, newAmount);
    }
    
    /**
     * @dev Withdraw funds from the faucet (owner only)
     * @param amount The amount to withdraw (0 to withdraw all)
     */
    function withdrawFunds(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        uint256 withdrawAmount = amount == 0 ? balance : amount;
        require(withdrawAmount <= balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: withdrawAmount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get faucet statistics
     * @return _balance Current faucet balance
     * @return _claimAmount Amount given per claim
     * @return _totalDistributed Total amount distributed
     * @return _totalClaims Total number of claims
     * @return _claimsRemaining Estimated claims remaining with current balance
     */
    function getFaucetStats() external view returns (
        uint256 _balance,
        uint256 _claimAmount,
        uint256 _totalDistributed,
        uint256 _totalClaims,
        uint256 _claimsRemaining
    ) {
        uint256 balance = address(this).balance;
        uint256 claimsRemaining = claimAmount > 0 ? balance / claimAmount : 0;
        
        return (
            balance,
            claimAmount,
            totalDistributed,
            totalClaims,
            claimsRemaining
        );
    }
    
    /**
     * @dev Get the faucet balance
     * @return The faucet's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get the estimated number of claims remaining
     * @return The number of claims that can still be made with current balance
     */
    function getClaimsRemaining() external view returns (uint256) {
        if (claimAmount == 0) {
            return 0;
        }
        return address(this).balance / claimAmount;
    }
    
    /**
     * @dev Transfer ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner is the same as current owner");
        
        owner = newOwner;
    }
    
    /**
     * @dev Receive function to accept ETH deposits
     */
    receive() external payable {
        emit FaucetFunded(msg.sender, msg.value);
    }
}
