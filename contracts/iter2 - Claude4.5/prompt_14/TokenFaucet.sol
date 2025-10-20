// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenFaucet {
    address public owner;
    IERC20 public token;
    uint256 public claimAmount;
    uint256 public claimInterval;
    
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public totalClaimed;
    
    uint256 public totalDistributed;
    uint256 public totalUsers;
    
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event ClaimIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(address _token, uint256 _claimAmount) {
        require(_token != address(0), "Token address cannot be zero");
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        
        owner = msg.sender;
        token = IERC20(_token);
        claimAmount = _claimAmount;
        claimInterval = 24 hours;
    }
    
    function claim() external {
        require(canClaim(msg.sender), "Cannot claim yet. Please wait for the claim interval to pass");
        require(token.balanceOf(address(this)) >= claimAmount, "Insufficient faucet balance");
        
        if (lastClaimTime[msg.sender] == 0) {
            totalUsers++;
        }
        
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += claimAmount;
        totalDistributed += claimAmount;
        
        require(token.transfer(msg.sender, claimAmount), "Token transfer failed");
        
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }
    
    function canClaim(address _user) public view returns (bool) {
        if (lastClaimTime[_user] == 0) {
            return true;
        }
        return block.timestamp >= lastClaimTime[_user] + claimInterval;
    }
    
    function getTimeUntilNextClaim(address _user) external view returns (uint256) {
        if (canClaim(_user)) {
            return 0;
        }
        return (lastClaimTime[_user] + claimInterval) - block.timestamp;
    }
    
    function getUserInfo(address _user) external view returns (
        uint256 lastClaim,
        uint256 totalClaimedAmount,
        bool canClaimNow,
        uint256 timeUntilNextClaim
    ) {
        bool claimable = canClaim(_user);
        uint256 timeLeft = 0;
        
        if (!claimable && lastClaimTime[_user] > 0) {
            timeLeft = (lastClaimTime[_user] + claimInterval) - block.timestamp;
        }
        
        return (
            lastClaimTime[_user],
            totalClaimed[_user],
            claimable,
            timeLeft
        );
    }
    
    function updateClaimAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Claim amount must be greater than 0");
        uint256 oldAmount = claimAmount;
        claimAmount = _newAmount;
        
        emit ClaimAmountUpdated(oldAmount, _newAmount);
    }
    
    function updateClaimInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval > 0, "Interval must be greater than 0");
        uint256 oldInterval = claimInterval;
        claimInterval = _newInterval;
        
        emit ClaimIntervalUpdated(oldInterval, _newInterval);
    }
    
    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        
        require(token.transfer(address(this), _amount), "Token transfer failed");
        
        emit TokensDeposited(msg.sender, _amount);
    }
    
    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(address(this)) >= _amount, "Insufficient contract balance");
        
        require(token.transfer(owner, _amount), "Token transfer failed");
        
        emit TokensWithdrawn(owner, _amount);
    }
    
    function getFaucetBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getFaucetStats() external view returns (
        uint256 balance,
        uint256 _claimAmount,
        uint256 _claimInterval,
        uint256 _totalDistributed,
        uint256 _totalUsers
    ) {
        return (
            token.balanceOf(address(this)),
            claimAmount,
            claimInterval,
            totalDistributed,
            totalUsers
        );
    }
}
