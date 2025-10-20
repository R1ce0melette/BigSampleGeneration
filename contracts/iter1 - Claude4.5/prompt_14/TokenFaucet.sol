// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenFaucet
 * @dev A token faucet that lets users claim a small fixed amount of tokens once every 24 hours
 */
contract TokenFaucet {
    // ERC20-like token functionality
    string public name = "Faucet Token";
    string public symbol = "FAUCET";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Faucet functionality
    address public owner;
    uint256 public claimAmount;
    uint256 public constant CLAIM_INTERVAL = 24 hours;
    
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public totalClaimed;
    
    uint256 public totalClaimsCount;
    uint256 public totalDistributed;
    
    event TokensClaimed(address indexed claimer, uint256 amount, uint256 timestamp);
    event FaucetRefilled(address indexed from, uint256 amount);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the faucet
     * @param _initialSupply Initial token supply for the faucet
     * @param _claimAmount Amount users can claim per request
     */
    constructor(uint256 _initialSupply, uint256 _claimAmount) {
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        
        owner = msg.sender;
        claimAmount = _claimAmount * 10**decimals;
        totalSupply = _initialSupply * 10**decimals;
        balances[address(this)] = totalSupply;
        
        emit Transfer(address(0), address(this), totalSupply);
    }
    
    /**
     * @dev Claim tokens from the faucet
     */
    function claim() external {
        require(
            block.timestamp >= lastClaimTime[msg.sender] + CLAIM_INTERVAL,
            "Must wait 24 hours between claims"
        );
        require(balances[address(this)] >= claimAmount, "Faucet is empty");
        
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += claimAmount;
        totalClaimsCount++;
        totalDistributed += claimAmount;
        
        balances[address(this)] -= claimAmount;
        balances[msg.sender] += claimAmount;
        
        emit Transfer(address(this), msg.sender, claimAmount);
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
    
    /**
     * @dev Check if an address can claim tokens
     * @param user The address to check
     * @return Whether the user can claim
     */
    function canClaim(address user) external view returns (bool) {
        return block.timestamp >= lastClaimTime[user] + CLAIM_INTERVAL &&
               balances[address(this)] >= claimAmount;
    }
    
    /**
     * @dev Get time remaining until next claim
     * @param user The address to check
     * @return Time remaining in seconds (0 if can claim now)
     */
    function getTimeUntilNextClaim(address user) external view returns (uint256) {
        uint256 nextClaimTime = lastClaimTime[user] + CLAIM_INTERVAL;
        
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }
        
        return nextClaimTime - block.timestamp;
    }
    
    /**
     * @dev Refill the faucet with tokens
     * @param amount The amount of tokens to add
     */
    function refillFaucet(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[address(this)] += amount;
        
        emit Transfer(msg.sender, address(this), amount);
        emit FaucetRefilled(msg.sender, amount);
    }
    
    /**
     * @dev Update the claim amount (only owner)
     * @param newAmount The new claim amount
     */
    function updateClaimAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Claim amount must be greater than 0");
        
        uint256 oldAmount = claimAmount;
        claimAmount = newAmount;
        
        emit ClaimAmountUpdated(oldAmount, newAmount);
    }
    
    /**
     * @dev Mint new tokens to the faucet (only owner)
     * @param amount The amount of tokens to mint
     */
    function mintToFaucet(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        
        totalSupply += amount;
        balances[address(this)] += amount;
        
        emit Transfer(address(0), address(this), amount);
    }
    
    /**
     * @dev Get faucet statistics
     * @return _claimAmount Amount per claim
     * @return _faucetBalance Current faucet balance
     * @return _totalClaims Total number of claims
     * @return _totalDistributed Total tokens distributed
     * @return _claimInterval Claim interval in seconds
     */
    function getFaucetStats() external view returns (
        uint256 _claimAmount,
        uint256 _faucetBalance,
        uint256 _totalClaims,
        uint256 _totalDistributed,
        uint256 _claimInterval
    ) {
        return (
            claimAmount,
            balances[address(this)],
            totalClaimsCount,
            totalDistributed,
            CLAIM_INTERVAL
        );
    }
    
    /**
     * @dev Get user claim information
     * @param user The address to query
     * @return _lastClaimTime When the user last claimed
     * @return _totalClaimed Total amount claimed by user
     * @return _canClaim Whether user can claim now
     * @return _timeUntilNext Time until next claim
     */
    function getUserClaimInfo(address user) external view returns (
        uint256 _lastClaimTime,
        uint256 _totalClaimed,
        bool _canClaim,
        uint256 _timeUntilNext
    ) {
        _lastClaimTime = lastClaimTime[user];
        _totalClaimed = totalClaimed[user];
        _canClaim = block.timestamp >= lastClaimTime[user] + CLAIM_INTERVAL &&
                    balances[address(this)] >= claimAmount;
        
        uint256 nextClaimTime = lastClaimTime[user] + CLAIM_INTERVAL;
        if (block.timestamp >= nextClaimTime) {
            _timeUntilNext = 0;
        } else {
            _timeUntilNext = nextClaimTime - block.timestamp;
        }
        
        return (_lastClaimTime, _totalClaimed, _canClaim, _timeUntilNext);
    }
    
    /**
     * @dev Get the faucet balance
     * @return The amount of tokens in the faucet
     */
    function getFaucetBalance() external view returns (uint256) {
        return balances[address(this)];
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    // ERC20 Functions
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) external view returns (uint256) {
        return allowances[_owner][spender];
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
