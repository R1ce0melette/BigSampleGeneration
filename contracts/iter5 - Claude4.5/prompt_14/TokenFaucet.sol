// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenFaucet {
    address public owner;
    uint256 public constant CLAIM_AMOUNT = 10 ether; // 10 tokens (assuming 18 decimals)
    uint256 public constant CLAIM_INTERVAL = 24 hours;
    
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public totalClaimed;
    
    uint256 public totalDistributed;
    
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetFunded(address indexed funder, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function claimTokens() external {
        require(canClaim(msg.sender), "Claim interval not elapsed");
        require(address(this).balance >= CLAIM_AMOUNT, "Faucet is empty");
        
        lastClaimTime[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += CLAIM_AMOUNT;
        totalDistributed += CLAIM_AMOUNT;
        
        (bool success, ) = msg.sender.call{value: CLAIM_AMOUNT}("");
        require(success, "Transfer failed");
        
        emit TokensClaimed(msg.sender, CLAIM_AMOUNT, block.timestamp);
    }
    
    function canClaim(address _user) public view returns (bool) {
        if (lastClaimTime[_user] == 0) {
            return true;
        }
        return block.timestamp >= lastClaimTime[_user] + CLAIM_INTERVAL;
    }
    
    function timeUntilNextClaim(address _user) external view returns (uint256) {
        if (canClaim(_user)) {
            return 0;
        }
        return (lastClaimTime[_user] + CLAIM_INTERVAL) - block.timestamp;
    }
    
    function getUserClaimInfo(address _user) external view returns (
        uint256 totalClaimedAmount,
        uint256 lastClaim,
        uint256 nextClaimTime,
        bool canClaimNow
    ) {
        return (
            totalClaimed[_user],
            lastClaimTime[_user],
            lastClaimTime[_user] + CLAIM_INTERVAL,
            canClaim(_user)
        );
    }
    
    function fundFaucet() external payable {
        require(msg.value > 0, "Must send tokens to fund faucet");
        emit FaucetFunded(msg.sender, msg.value);
    }
    
    function getFaucetBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, _amount);
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    receive() external payable {
        emit FaucetFunded(msg.sender, msg.value);
    }
}
