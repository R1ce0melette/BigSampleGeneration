// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address payable public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalRaised;
    mapping(address => uint256) public contributions;

    enum State { Funding, Succeeded, Failed }
    State public currentState = State.Funding;

    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalRaised);
    event CampaignFailed();
    event FundsWithdrawn(uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        owner = payable(msg.sender);
        fundingGoal = _fundingGoal * 1 ether;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() public payable {
        require(currentState == State.Funding, "Campaign is not active.");
        require(block.timestamp < deadline, "Campaign has ended.");
        require(msg.value > 0, "Contribution must be greater than zero.");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Contribution(msg.sender, msg.value);

        if (totalRaised >= fundingGoal) {
            currentState = State.Succeeded;
            emit GoalReached(totalRaised);
        }
    }

    function checkCampaignStatus() public {
        require(currentState == State.Funding, "Campaign has already succeeded or failed.");
        if (block.timestamp >= deadline) {
            if (totalRaised < fundingGoal) {
                currentState = State.Failed;
                emit CampaignFailed();
            } else {
                currentState = State.Succeeded;
                emit GoalReached(totalRaised);
            }
        }
    }

    function withdrawFunds() public onlyOwner {
        require(currentState == State.Succeeded, "Campaign has not succeeded.");
        uint256 amount = address(this).balance;
        owner.transfer(amount);
        emit FundsWithdrawn(amount);
    }

    function getRefund() public {
        require(currentState == State.Failed, "Campaign has not failed.");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution to refund.");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refunded(msg.sender, amount);
    }
}
