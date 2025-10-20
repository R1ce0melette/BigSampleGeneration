// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    address public owner;
    IERC20 public token;
    uint256 public claimAmount;
    uint256 public constant CLAIM_INTERVAL = 24 hours;
    
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public totalClaimed;
    
    uint256 public totalDispensed;
    uint256 public totalUsers;
    
    // Events
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event TokensDeposited(address indexed from, uint256 amount);
    event TokensWithdrawn(address indexed to, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the faucet
     * @param _token Address of the ERC20 token contract
     * @param _claimAmount Amount of tokens users can claim per request
     */
    constructor(address _token, uint256 _claimAmount) {
        require(_token != address(0), "Token address cannot be zero");
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        
        owner = msg.sender;
        token = IERC20(_token);
        claimAmount = _claimAmount;
    }
    
    /**
     * @dev Claim tokens from the faucet
     */
    function claimTokens() external {
        require(canClaim(msg.sender), "Cannot claim yet, please wait");
        require(token.balanceOf(address(this)) >= claimAmount, "Faucet is empty");
        
        // Track if this is a new user
        if (lastClaimTime[msg.sender] == 0) {
            totalUsers++;
        }
        
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += claimAmount;
        totalDispensed += claimAmount;
        
        require(token.transfer(msg.sender, claimAmount), "Token transfer failed");
        
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
    
    /**
     * @dev Check if a user can claim tokens
     * @param _user The address of the user
     * @return True if the user can claim, false otherwise
     */
    function canClaim(address _user) public view returns (bool) {
        if (lastClaimTime[_user] == 0) {
            return true; // First time claim
        }
        
        return block.timestamp >= lastClaimTime[_user] + CLAIM_INTERVAL;
    }
    
    /**
     * @dev Get the time remaining until next claim
     * @param _user The address of the user
     * @return The time remaining in seconds (0 if can claim now)
     */
    function getTimeUntilNextClaim(address _user) external view returns (uint256) {
        if (canClaim(_user)) {
            return 0;
        }
        
        uint256 nextClaimTime = lastClaimTime[_user] + CLAIM_INTERVAL;
        return nextClaimTime - block.timestamp;
    }
    
    /**
     * @dev Get user claim information
     * @param _user The address of the user
     * @return lastClaim The timestamp of the last claim
     * @return totalClaimedAmount The total amount claimed by the user
     * @return canClaimNow Whether the user can claim now
     * @return timeUntilNext Time until next claim (0 if can claim now)
     */
    function getUserInfo(address _user) external view returns (
        uint256 lastClaim,
        uint256 totalClaimedAmount,
        bool canClaimNow,
        uint256 timeUntilNext
    ) {
        lastClaim = lastClaimTime[_user];
        totalClaimedAmount = totalClaimed[_user];
        canClaimNow = canClaim(_user);
        
        if (canClaimNow) {
            timeUntilNext = 0;
        } else {
            uint256 nextClaimTime = lastClaimTime[_user] + CLAIM_INTERVAL;
            timeUntilNext = nextClaimTime - block.timestamp;
        }
        
        return (lastClaim, totalClaimedAmount, canClaimNow, timeUntilNext);
    }
    
    /**
     * @dev Update the claim amount
     * @param _newAmount The new claim amount
     */
    function updateClaimAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Claim amount must be greater than 0");
        
        uint256 oldAmount = claimAmount;
        claimAmount = _newAmount;
        
        emit ClaimAmountUpdated(oldAmount, _newAmount);
    }
    
    /**
     * @dev Deposit tokens to the faucet
     * @param _amount The amount of tokens to deposit
     */
    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        
        require(token.transfer(address(this), _amount), "Token transfer failed");
        
        emit TokensDeposited(msg.sender, _amount);
    }
    
    /**
     * @dev Withdraw tokens from the faucet (owner only)
     * @param _amount The amount of tokens to withdraw
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance");
        
        require(token.transfer(owner, _amount), "Token transfer failed");
        
        emit TokensWithdrawn(owner, _amount);
    }
    
    /**
     * @dev Get faucet balance
     * @return The token balance of the faucet
     */
    function getFaucetBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    /**
     * @dev Get faucet statistics
     * @return _claimAmount The amount per claim
     * @return _totalDispensed Total tokens dispensed
     * @return _totalUsers Total number of users
     * @return _balance Current faucet balance
     */
    function getStatistics() external view returns (
        uint256 _claimAmount,
        uint256 _totalDispensed,
        uint256 _totalUsers,
        uint256 _balance
    ) {
        return (
            claimAmount,
            totalDispensed,
            totalUsers,
            token.balanceOf(address(this))
        );
    }
}
