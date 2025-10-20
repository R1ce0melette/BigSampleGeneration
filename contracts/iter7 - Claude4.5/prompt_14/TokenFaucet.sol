// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenFaucet
 * @dev A token faucet that lets users claim a small fixed amount of tokens once every 24 hours
 */
contract TokenFaucet {
    address public owner;
    uint256 public claimAmount;
    uint256 public claimInterval = 24 hours;
    
    // Token balances
    mapping(address => uint256) public balances;
    
    // Last claim timestamp for each user
    mapping(address => uint256) public lastClaimTime;
    
    // Total supply tracking
    uint256 public totalSupply;
    uint256 public totalClaimed;
    
    // Events
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetRefilled(address indexed funder, uint256 amount);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event ClaimIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor to initialize the faucet
     * @param _claimAmount The amount of tokens users can claim per request
     */
    constructor(uint256 _claimAmount) {
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        owner = msg.sender;
        claimAmount = _claimAmount;
    }
    
    /**
     * @dev Claim tokens from the faucet
     * Requirements:
     * - User must wait 24 hours between claims
     * - Faucet must have sufficient balance
     */
    function claim() external {
        require(canClaim(msg.sender), "Cannot claim yet, please wait");
        require(balances[address(this)] >= claimAmount, "Faucet is empty");
        
        lastClaimTime[msg.sender] = block.timestamp;
        balances[address(this)] -= claimAmount;
        balances[msg.sender] += claimAmount;
        totalClaimed += claimAmount;
        
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
    
    /**
     * @dev Check if a user can claim tokens
     * @param user The address to check
     * @return True if the user can claim, false otherwise
     */
    function canClaim(address user) public view returns (bool) {
        if (lastClaimTime[user] == 0) {
            return true; // First time claim
        }
        return block.timestamp >= lastClaimTime[user] + claimInterval;
    }
    
    /**
     * @dev Get the time remaining until next claim
     * @param user The address to check
     * @return The time remaining in seconds, or 0 if can claim now
     */
    function timeUntilNextClaim(address user) external view returns (uint256) {
        if (canClaim(user)) {
            return 0;
        }
        uint256 nextClaimTime = lastClaimTime[user] + claimInterval;
        return nextClaimTime - block.timestamp;
    }
    
    /**
     * @dev Refill the faucet with tokens (anyone can refill)
     * @param amount The amount of tokens to add to the faucet
     */
    function refill(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[address(this)] += amount;
        
        emit FaucetRefilled(msg.sender, amount);
    }
    
    /**
     * @dev Owner mints tokens directly to the faucet
     * @param amount The amount of tokens to mint
     */
    function mintToFaucet(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        
        balances[address(this)] += amount;
        totalSupply += amount;
        
        emit FaucetRefilled(msg.sender, amount);
    }
    
    /**
     * @dev Owner mints tokens to a specific address
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        balances[to] += amount;
        totalSupply += amount;
    }
    
    /**
     * @dev Transfer tokens to another address
     * @param to The recipient address
     * @param amount The amount to transfer
     */
    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit TokensTransferred(msg.sender, to, amount);
    }
    
    /**
     * @dev Get the balance of an address
     * @param account The address to query
     * @return The token balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    /**
     * @dev Get the faucet balance
     * @return The faucet's token balance
     */
    function getFaucetBalance() external view returns (uint256) {
        return balances[address(this)];
    }
    
    /**
     * @dev Get caller's balance
     * @return The caller's token balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Update the claim amount (only owner)
     * @param newAmount The new claim amount
     */
    function setClaimAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Claim amount must be greater than 0");
        
        uint256 oldAmount = claimAmount;
        claimAmount = newAmount;
        
        emit ClaimAmountUpdated(oldAmount, newAmount);
    }
    
    /**
     * @dev Update the claim interval (only owner)
     * @param newInterval The new claim interval in seconds
     */
    function setClaimInterval(uint256 newInterval) external onlyOwner {
        require(newInterval > 0, "Claim interval must be greater than 0");
        
        uint256 oldInterval = claimInterval;
        claimInterval = newInterval;
        
        emit ClaimIntervalUpdated(oldInterval, newInterval);
    }
    
    /**
     * @dev Get faucet statistics
     * @return _claimAmount The amount per claim
     * @return _claimInterval The interval between claims
     * @return _faucetBalance The current faucet balance
     * @return _totalSupply The total supply of tokens
     * @return _totalClaimed The total amount claimed from faucet
     */
    function getFaucetStats() external view returns (
        uint256 _claimAmount,
        uint256 _claimInterval,
        uint256 _faucetBalance,
        uint256 _totalSupply,
        uint256 _totalClaimed
    ) {
        return (
            claimAmount,
            claimInterval,
            balances[address(this)],
            totalSupply,
            totalClaimed
        );
    }
    
    /**
     * @dev Get user claim information
     * @param user The user address
     * @return lastClaim The last claim timestamp
     * @return canClaimNow Whether the user can claim now
     * @return timeUntilClaim Time until next claim (0 if can claim now)
     */
    function getUserClaimInfo(address user) external view returns (
        uint256 lastClaim,
        bool canClaimNow,
        uint256 timeUntilClaim
    ) {
        bool canClaimStatus = canClaim(user);
        uint256 timeRemaining = 0;
        
        if (!canClaimStatus && lastClaimTime[user] > 0) {
            uint256 nextClaimTime = lastClaimTime[user] + claimInterval;
            timeRemaining = nextClaimTime - block.timestamp;
        }
        
        return (
            lastClaimTime[user],
            canClaimStatus,
            timeRemaining
        );
    }
}
