// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        require(msg.value > 0, "Contribution must be greater than 0");

        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;

        emit ContributionReceived(msg.sender, msg.value);

        if (totalFundsRaised >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }

    function checkGoalReached() public {
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(!campaignClosed, "Campaign already closed");

        if (totalFundsRaised >= fundingGoal) {
            goalReached = true;
        }
    }

    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        require(!campaignClosed, "Campaign already closed");
        
        checkGoalReached();
        require(goalReached, "Funding goal not reached");

        campaignClosed = true;
        uint256 amount = totalFundsRaised;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner, amount);
    }

    function refund() external {
        require(block.timestamp >= deadline, "Campaign is still ongoing");
        
        if (!campaignClosed && !goalReached) {
            checkGoalReached();
        }
        
        require(!goalReached, "Goal was reached, no refunds");
        require(contributions[msg.sender] > 0, "No contribution to refund");

        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund failed");

        emit RefundIssued(msg.sender, amount);
    }

    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }

    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}
