// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address payable public beneficiary;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public amountRaised;

    mapping(address => uint256) public contributions;
    bool public fundingGoalReached = false;
    bool public campaignClosed = false;

    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event BeneficiaryPaid(address beneficiary);
    event Refunded(address indexed contributor, uint256 amount);

    constructor(uint256 _fundingGoal, uint256 _durationInDays, address payable _beneficiary) {
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        beneficiary = _beneficiary;
    }

    function contribute() public payable {
        require(!campaignClosed, "Campaign is closed.");
        require(block.timestamp < deadline, "Campaign has ended.");
        
        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;
        
        emit Contribution(msg.sender, msg.value);

        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(amountRaised);
        }
    }

    function checkGoal() public {
        require(!campaignClosed, "Campaign is already closed.");
        if (block.timestamp >= deadline) {
            campaignClosed = true;
            if (fundingGoalReached) {
                payOut();
            }
        }
    }

    function payOut() internal {
        require(campaignClosed && fundingGoalReached, "Payout conditions not met.");
        uint256 totalAmount = address(this).balance;
        beneficiary.transfer(totalAmount);
        emit BeneficiaryPaid(beneficiary);
    }

    function refund() public {
        require(block.timestamp >= deadline && !fundingGoalReached, "Refund conditions not met.");
        require(contributions[msg.sender] > 0, "No contribution to refund.");

        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(amountToRefund);
        emit Refunded(msg.sender, amountToRefund);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
