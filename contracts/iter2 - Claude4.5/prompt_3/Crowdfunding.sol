// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFundsRaised;
    bool public fundingGoalReached;
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
        fundingGoalReached = false;
        campaignClosed = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline has not passed yet");
        _;
    }
    
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Deadline has passed");
        _;
    }
    
    function contribute() external payable beforeDeadline {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(!campaignClosed, "Campaign is closed");
        
        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        if (totalFundsRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }
    
    function checkGoalReached() external afterDeadline {
        require(!campaignClosed, "Campaign is already closed");
        
        if (totalFundsRaised >= fundingGoal) {
            fundingGoalReached = true;
        }
        campaignClosed = true;
    }
    
    function withdrawFunds() external onlyOwner afterDeadline {
        require(fundingGoalReached, "Funding goal was not reached");
        require(!campaignClosed || totalFundsRaised >= fundingGoal, "Cannot withdraw");
        
        uint256 amount = address(this).balance;
        campaignClosed = true;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    function refund() external afterDeadline {
        require(!fundingGoalReached, "Funding goal was reached, no refunds");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, amount);
    }
    
    function getContribution(address _contributor) external view returns (uint256) {
        return contributions[_contributor];
    }
    
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}
