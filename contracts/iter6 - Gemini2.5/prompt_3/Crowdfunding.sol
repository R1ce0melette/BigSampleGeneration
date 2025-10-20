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

    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 amountRaised);
    event GoalNotReached();
    event FundsWithdrawn(uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier inState(State _state) {
        require(currentState == _state, "Invalid state.");
        _;
    }

    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        owner = payable(msg.sender);
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() external payable inState(State.Fundraising) {
        require(block.timestamp < deadline, "Campaign has ended.");
        require(msg.value > 0, "Contribution must be greater than zero.");

        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;

        emit Contribution(msg.sender, msg.value);

        if (amountRaised >= fundingGoal) {
            currentState = State.GoalReached;
            emit GoalReached(amountRaised);
        }
    }

    function checkCampaignStatus() external {
        if (currentState == State.Fundraising && block.timestamp >= deadline) {
            if (amountRaised < fundingGoal) {
                currentState = State.GoalNotReached;
                emit GoalNotReached();
            } else {
                currentState = State.GoalReached;
                emit GoalReached(amountRaised);
            }
        }
    }

    function withdraw() external onlyOwner inState(State.GoalReached) {
        uint256 amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed.");
        emit FundsWithdrawn(amount);
    }

    function getRefund() external inState(State.GoalNotReached) {
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contribution to refund.");

        contributions[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: contribution}("");
        require(success, "Refund failed.");

        emit Refunded(msg.sender, contribution);
    }
}
