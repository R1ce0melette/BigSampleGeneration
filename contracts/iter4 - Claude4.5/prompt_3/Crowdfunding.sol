// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Crowdfunding
 * @dev A simple crowdfunding contract where users contribute ETH toward a goal
 */
contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFundsRaised;
    bool public fundingGoalReached;
    bool public campaignClosed;
    
    // Mapping to track contributions per user
    mapping(address => uint256) public contributions;
    
    // Events
    event ContributionReceived(address indexed contributor, uint256 amount);
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
        fundingGoalReached = false;
        campaignClosed = false;
    }
    
    /**
     * @dev Allows users to contribute ETH to the campaign
     */
    function contribute() external payable {
        require(!campaignClosed, "Campaign is closed");
        require(block.timestamp < deadline, "Campaign deadline has passed");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        if (totalFundsRaised >= fundingGoal && !fundingGoalReached) {
            fundingGoalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }
    
    /**
     * @dev Checks if the deadline has passed and closes the campaign
     */
    function checkGoalReached() public {
        require(block.timestamp >= deadline, "Campaign is still active");
        require(!campaignClosed, "Campaign already closed");
        
        campaignClosed = true;
        
        if (totalFundsRaised >= fundingGoal) {
            fundingGoalReached = true;
        }
    }
    
    /**
     * @dev Allows the owner to withdraw funds if the goal was reached
     */
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(campaignClosed, "Campaign is not closed yet");
        require(fundingGoalReached, "Funding goal was not reached");
        require(totalFundsRaised > 0, "No funds to withdraw");
        
        uint256 amount = totalFundsRaised;
        totalFundsRaised = 0;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Allows contributors to claim refunds if the goal was not reached
     */
    function claimRefund() external {
        require(campaignClosed, "Campaign is not closed yet");
        require(!fundingGoalReached, "Funding goal was reached, no refunds");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, amount);
    }
    
    /**
     * @dev Returns the contribution of the caller
     * @return The contribution amount
     */
    function getMyContribution() external view returns (uint256) {
        return contributions[msg.sender];
    }
    
    /**
     * @dev Returns the time remaining until the deadline
     * @return The time remaining in seconds, or 0 if deadline has passed
     */
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    /**
     * @dev Returns whether the campaign is still active
     * @return True if active, false otherwise
     */
    function isActive() external view returns (bool) {
        return !campaignClosed && block.timestamp < deadline;
    }
}
