// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFunds;
    bool public fundingGoalReached;
    bool public campaignClosed;
    
    mapping(address => uint256) public contributions;
    
    // Events
    event ContributionReceived(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalFunds);
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
     * @dev Contribute ETH to the crowdfunding campaign
     */
    function contribute() external payable {
        require(!campaignClosed, "Campaign is closed");
        require(block.timestamp < deadline, "Campaign deadline has passed");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        if (totalFunds >= fundingGoal && !fundingGoalReached) {
            fundingGoalReached = true;
            emit GoalReached(totalFunds);
        }
    }
    
    /**
     * @dev Check if the deadline has passed and finalize the campaign
     */
    function checkGoalReached() public {
        require(!campaignClosed, "Campaign already closed");
        require(block.timestamp >= deadline, "Deadline has not passed yet");
        
        campaignClosed = true;
        
        if (totalFunds >= fundingGoal) {
            fundingGoalReached = true;
        }
    }
    
    /**
     * @dev Owner withdraws funds if goal is reached
     */
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(campaignClosed, "Campaign is not closed yet");
        require(fundingGoalReached, "Funding goal not reached");
        require(totalFunds > 0, "No funds to withdraw");
        
        uint256 amount = totalFunds;
        totalFunds = 0;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Contributors can claim refunds if goal is not reached
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
     * @dev Get the contribution amount for a specific contributor
     * @param contributor The address of the contributor
     * @return The amount contributed
     */
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }
    
    /**
     * @dev Get the remaining time until deadline
     * @return The remaining time in seconds (0 if deadline has passed)
     */
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    /**
     * @dev Get the campaign status
     * @return _totalFunds The total funds raised
     * @return _goalReached Whether the goal was reached
     * @return _closed Whether the campaign is closed
     * @return _timeRemaining The remaining time in seconds
     */
    function getCampaignStatus() external view returns (
        uint256 _totalFunds,
        bool _goalReached,
        bool _closed,
        uint256 _timeRemaining
    ) {
        _totalFunds = totalFunds;
        _goalReached = fundingGoalReached;
        _closed = campaignClosed;
        _timeRemaining = block.timestamp >= deadline ? 0 : deadline - block.timestamp;
    }
}
