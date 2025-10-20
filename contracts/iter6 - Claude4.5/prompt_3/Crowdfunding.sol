// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Crowdfunding
 * @dev A simple crowdfunding contract where users can contribute ETH toward a funding goal
 * If the goal is not met by the deadline, contributors can claim refunds
 */
contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFundsRaised;
    bool public goalReached;
    bool public campaignClosed;
    
    // Mapping to track contributions per address
    mapping(address => uint256) public contributions;
    
    // Events
    event ContributionReceived(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    
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
     * - Contribution must be greater than 0
     */
    function contribute() external payable {
        require(!campaignClosed, "Campaign is closed");
        require(block.timestamp < deadline, "Campaign deadline has passed");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        // Check if goal is reached
        if (totalFundsRaised >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }
    
    /**
     * @dev Check and finalize the campaign after deadline
     * Can be called by anyone after the deadline
     */
    function checkGoalReached() external {
        require(block.timestamp >= deadline, "Campaign deadline has not passed yet");
        require(!campaignClosed, "Campaign already closed");
        
        campaignClosed = true;
        
        if (totalFundsRaised >= fundingGoal) {
            goalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }
    
    /**
     * @dev Withdraw funds if goal was reached
     * Can only be called by the owner
     * Requirements:
     * - Campaign must be closed
     * - Goal must be reached
     */
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(campaignClosed, "Campaign is not closed yet");
        require(goalReached, "Funding goal was not reached");
        require(totalFundsRaised > 0, "No funds to withdraw");
        
        uint256 amount = totalFundsRaised;
        totalFundsRaised = 0;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Claim refund if goal was not reached
     * Requirements:
     * - Campaign must be closed
     * - Goal must not be reached
     * - Contributor must have contributed
     */
    function claimRefund() external {
        require(campaignClosed, "Campaign is not closed yet");
        require(!goalReached, "Funding goal was reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contributions to refund");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit RefundClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Get the contribution amount for a specific address
     * @param contributor The address of the contributor
     * @return The amount contributed by the address
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
     * @dev Check if the campaign is still active
     * @return True if the campaign is active, false otherwise
     */
    function isActive() external view returns (bool) {
        return !campaignClosed && block.timestamp < deadline;
    }
}
