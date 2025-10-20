// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenFaucet {
    address public owner;
    uint256 public claimAmount;
    uint256 public claimInterval;
    uint256 public totalSupply;
    uint256 public totalClaimed;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastClaimTime;

    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetFunded(address indexed funder, uint256 amount);
    event ClaimAmountUpdated(uint256 newAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _claimAmount) {
        owner = msg.sender;
        claimAmount = _claimAmount;
        claimInterval = 24 hours;
    }

    function claimTokens() external {
        require(canClaim(msg.sender), "Cannot claim yet. Please wait for the cooldown period");
        require(totalSupply - totalClaimed >= claimAmount, "Faucet is empty");

        lastClaimTime[msg.sender] = block.timestamp;
        balances[msg.sender] += claimAmount;
        totalClaimed += claimAmount;

        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }

    function canClaim(address user) public view returns (bool) {
        if (lastClaimTime[user] == 0) {
            return true;
        }
        return block.timestamp >= lastClaimTime[user] + claimInterval;
    }

    function getTimeUntilNextClaim(address user) external view returns (uint256) {
        if (canClaim(user)) {
            return 0;
        }
        uint256 nextClaimTime = lastClaimTime[user] + claimInterval;
        return nextClaimTime - block.timestamp;
    }

    function fundFaucet(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        totalSupply += amount;
        emit FaucetFunded(msg.sender, amount);
    }

    function updateClaimAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Claim amount must be greater than 0");
        claimAmount = newAmount;
        emit ClaimAmountUpdated(newAmount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getRemainingTokens() external view returns (uint256) {
        return totalSupply - totalClaimed;
    }

    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Cannot transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
