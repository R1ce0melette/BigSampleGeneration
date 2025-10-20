// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Crowdfunding
 * @dev Simple crowdfunding contract where users contribute ETH toward a goal with refund mechanism
 */
contract Crowdfunding {
    // State variables
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFunds;
    bool public goalReached;
    bool public campaignClosed;

    mapping(address => uint256) public contributions;
    address[] public contributors;
    mapping(address => bool) public isContributor;

    // Events
    event ContributionReceived(address indexed contributor, uint256 amount, uint256 timestamp);
    event GoalReached(uint256 totalAmount, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount, uint256 timestamp);
    event RefundIssued(address indexed contributor, uint256 amount, uint256 timestamp);
    event CampaignClosed(uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Campaign has ended");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Campaign is still active");
        _;
    }

    modifier campaignActive() {
        require(!campaignClosed, "Campaign is closed");
        _;
    }

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
     * @dev Contribute ETH to the campaign
     */
    function contribute() public payable beforeDeadline campaignActive {
        require(msg.value > 0, "Contribution must be greater than 0");

        if (!isContributor[msg.sender]) {
            contributors.push(msg.sender);
            isContributor[msg.sender] = true;
        }

        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit ContributionReceived(msg.sender, msg.value, block.timestamp);

        if (totalFunds >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalFunds, block.timestamp);
        }
    }

    /**
     * @dev Check if goal is reached
     * @return true if goal is reached
     */
    function checkGoalReached() public view returns (bool) {
        return totalFunds >= fundingGoal;
    }

    /**
     * @dev Withdraw funds if goal is reached (only owner)
     */
    function withdrawFunds() public onlyOwner afterDeadline campaignActive {
        require(totalFunds >= fundingGoal, "Funding goal not reached");

        campaignClosed = true;
        uint256 amount = address(this).balance;

        payable(owner).transfer(amount);

        emit FundsWithdrawn(owner, amount, block.timestamp);
        emit CampaignClosed(block.timestamp);
    }

    /**
     * @dev Refund contribution if goal is not reached
     */
    function refund() public afterDeadline campaignActive {
        require(totalFunds < fundingGoal, "Funding goal was reached, no refunds");
        require(contributions[msg.sender] > 0, "No contribution to refund");

        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit RefundIssued(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Close campaign (mark as closed after all refunds)
     */
    function closeCampaign() public onlyOwner afterDeadline {
        require(!campaignClosed, "Campaign already closed");
        campaignClosed = true;
        emit CampaignClosed(block.timestamp);
    }

    /**
     * @dev Get contribution amount for caller
     * @return Contribution amount
     */
    function getMyContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    /**
     * @dev Get contribution amount for a specific address
     * @param contributor Address to check
     * @return Contribution amount
     */
    function getContribution(address contributor) public view returns (uint256) {
        return contributions[contributor];
    }

    /**
     * @dev Get all contributors
     * @return Array of contributor addresses
     */
    function getContributors() public view returns (address[] memory) {
        return contributors;
    }

    /**
     * @dev Get number of contributors
     * @return Total contributor count
     */
    function getContributorCount() public view returns (uint256) {
        return contributors.length;
    }

    /**
     * @dev Get time remaining until deadline
     * @return Seconds remaining (0 if deadline passed)
     */
    function getTimeRemaining() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    /**
     * @dev Get campaign status
     * @return _totalFunds Total funds raised
     * @return _fundingGoal Funding goal
     * @return _goalReached Whether goal is reached
     * @return _deadline Campaign deadline
     * @return _campaignClosed Whether campaign is closed
     */
    function getCampaignStatus() 
        public 
        view 
        returns (
            uint256 _totalFunds,
            uint256 _fundingGoal,
            bool _goalReached,
            uint256 _deadline,
            bool _campaignClosed
        ) 
    {
        return (totalFunds, fundingGoal, goalReached, deadline, campaignClosed);
    }

    /**
     * @dev Get progress percentage (in basis points, 10000 = 100%)
     * @return Progress percentage
     */
    function getProgressPercentage() public view returns (uint256) {
        if (fundingGoal == 0) return 0;
        return (totalFunds * 10000) / fundingGoal;
    }

    /**
     * @dev Check if campaign is active
     * @return true if active
     */
    function isCampaignActive() public view returns (bool) {
        return !campaignClosed && block.timestamp < deadline;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        contribute();
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        contribute();
    }
}
