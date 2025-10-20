// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFunds;
    bool public goalReached;
    bool public campaignClosed;
    
    mapping(address => uint256) public contributions;
    
    event ContributionReceived(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);
    
    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        owner = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        goalReached = false;
        campaignClosed = false;
    }
    
    function contribute() external payable {
        require(block.timestamp < deadline, "Campaign has ended");
        require(!campaignClosed, "Campaign is closed");
        require(msg.value > 0, "Contribution must be greater than zero");
        
        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        if (totalFunds >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalFunds);
        }
    }
    
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= deadline, "Campaign still ongoing");
        require(goalReached, "Funding goal not reached");
        require(!campaignClosed, "Campaign already closed");
        
        campaignClosed = true;
        uint256 amount = totalFunds;
        totalFunds = 0;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    function refund() external {
        require(block.timestamp >= deadline, "Campaign still ongoing");
        require(!goalReached, "Goal was reached, no refunds");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        totalFunds -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund failed");
        
        emit RefundIssued(msg.sender, amount);
    }
    
    function checkGoalReached() external view returns (bool) {
        return goalReached;
    }
    
    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }
}
