// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Crowdfunding
 * @dev A simple crowdfunding contract where users can contribute ETH toward a funding goal
 * and receive refunds if the goal is not met by the deadline
 */
contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalContributions;
    bool public goalReached;
    bool public campaignClosed;
    
    // Mapping to track contributions per address
    mapping(address => uint256) public contributions;
    
    // Events
    event ContributionReceived(address indexed contributor, uint256 amount, uint256 totalContributions);
    event GoalReached(uint256 totalAmount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);
    
    /**
     * @dev Constructor to initialize the crowdfunding campaign
     * @param _fundingGoal The funding goal in wei
     * @param _durationInDays The duration of the campaign in days
     */
    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        require(_fundingGoal > 0, "Funding goal must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        owner = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        goalReached = false;
        campaignClosed = false;
    }
    
    /**
     * @dev Contribute ETH to the crowdfunding campaign
     * Requirements:
     * - Campaign must not be closed
     * - Deadline must not have passed
     * - Contribution amount must be greater than 0
     */
    function contribute() external payable {
        require(!campaignClosed, "Campaign is closed");
        require(block.timestamp < deadline, "Campaign deadline has passed");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value, totalContributions);
        
        if (totalContributions >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalContributions);
        }
    }
    
    /**
     * @dev Check if the goal has been reached
     */
    function checkGoalReached() public {
        if (totalContributions >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalContributions);
        }
    }
    
    /**
     * @dev Withdraw funds if goal is reached (only owner)
     * Requirements:
     * - Caller must be the owner
     * - Goal must be reached
     * - Campaign must not already be closed
     */
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(goalReached, "Funding goal not reached");
        require(!campaignClosed, "Campaign already closed");
        
        campaignClosed = true;
        uint256 amount = address(this).balance;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Request a refund if the goal was not reached and deadline has passed
     * Requirements:
     * - Deadline must have passed
     * - Goal must not be reached
     * - Caller must have made contributions
     */
    function refund() external {
        require(block.timestamp >= deadline, "Campaign deadline has not passed yet");
        require(!goalReached, "Funding goal was reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contributions to refund");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, amount);
    }
    
    /**
     * @dev Get the contribution amount for a specific address
     * @param contributor The address to query
     * @return The contribution amount
     */
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }
    
    /**
     * @dev Get the remaining time until deadline
     * @return The remaining time in seconds, or 0 if deadline has passed
     */
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    /**
     * @dev Get campaign status
     * @return _goalReached Whether the goal has been reached
     * @return _campaignClosed Whether the campaign is closed
     * @return _timeRemaining Time remaining until deadline
     */
    function getCampaignStatus() external view returns (bool _goalReached, bool _campaignClosed, uint256 _timeRemaining) {
        _goalReached = goalReached;
        _campaignClosed = campaignClosed;
        _timeRemaining = block.timestamp >= deadline ? 0 : deadline - block.timestamp;
    }
}
