// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Crowdfunding
 * @dev A simple crowdfunding contract where users can contribute ETH toward a funding goal
 * Contributors can get refunded if the goal is not met by the deadline
 */
contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFundsRaised;
    bool public goalReached;
    bool public campaignClosed;
    
    mapping(address => uint256) public contributions;
    
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
        goalReached = false;
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
        totalFundsRaised += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        if (totalFundsRaised >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }
    
    /**
     * @dev Check if the goal has been reached
     */
    function checkGoalReached() public {
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(!campaignClosed, "Campaign already closed");
        
        if (totalFundsRaised >= fundingGoal) {
            goalReached = true;
        }
        
        campaignClosed = true;
    }
    
    /**
     * @dev Owner withdraws funds if goal is reached
     */
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(totalFundsRaised >= fundingGoal, "Funding goal not reached");
        
        if (!campaignClosed) {
            campaignClosed = true;
            goalReached = true;
        }
        
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Contributors can get a refund if the goal is not met
     */
    function refund() external {
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(totalFundsRaised < fundingGoal, "Funding goal was reached");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        if (!campaignClosed) {
            campaignClosed = true;
        }
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, amount);
    }
    
    /**
     * @dev Get contribution amount for a specific address
     * @param contributor The address of the contributor
     * @return The contribution amount
     */
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }
    
    /**
     * @dev Get time remaining until deadline
     * @return Time remaining in seconds (0 if deadline passed)
     */
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    /**
     * @dev Get campaign status
     * @return _goalReached Whether goal was reached
     * @return _campaignClosed Whether campaign is closed
     * @return _totalFundsRaised Total funds raised
     * @return _timeRemaining Time remaining in seconds
     */
    function getCampaignStatus() external view returns (
        bool _goalReached,
        bool _campaignClosed,
        uint256 _totalFundsRaised,
        uint256 _timeRemaining
    ) {
        _goalReached = goalReached;
        _campaignClosed = campaignClosed;
        _totalFundsRaised = totalFundsRaised;
        
        if (block.timestamp >= deadline) {
            _timeRemaining = 0;
        } else {
            _timeRemaining = deadline - block.timestamp;
        }
    }
}
