// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address payable public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public amountRaised;
    mapping(address => uint256) public contributions;

    enum State { Fundraising, GoalReached, GoalNotReached }
    State public currentState = State.Fundraising;

    event ContributionMade(address indexed contributor, uint256 amount);
    event ProjectSuccess(uint256 totalRaised);
    event ProjectFailure();
    event FundsWithdrawn(uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);

    constructor(uint256 _fundingGoalInEther, uint256 _durationInDays) {
        owner = payable(msg.sender);
        fundingGoal = _fundingGoalInEther * 1 ether;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() public payable {
        require(currentState == State.Fundraising, "Campaign is not active.");
        require(block.timestamp < deadline, "Campaign has ended.");
        
        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;
        
        emit ContributionMade(msg.sender, msg.value);
    }

    function checkGoal() public {
        require(currentState == State.Fundraising, "Goal has already been checked.");
        require(block.timestamp >= deadline, "Campaign is still ongoing.");

        if (amountRaised >= fundingGoal) {
            currentState = State.GoalReached;
            emit ProjectSuccess(amountRaised);
        } else {
            currentState = State.GoalNotReached;
            emit ProjectFailure();
        }
    }

    function withdrawFunds() public {
        require(currentState == State.GoalReached, "Funding goal not reached.");
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        
        emit FundsWithdrawn(balance);
    }

    function getRefund() public {
        require(currentState == State.GoalNotReached, "Funding goal was reached, no refunds available.");
        require(contributions[msg.sender] > 0, "You have no funds to withdraw.");

        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(amountToRefund);
        
        emit RefundIssued(msg.sender, amountToRefund);
    }
}
