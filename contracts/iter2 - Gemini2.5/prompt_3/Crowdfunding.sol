// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public immutable beneficiary;
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline;

    uint256 public amountRaised;
    mapping(address => uint256) public contributions;

    enum State { Funding, Succeeded, Failed }
    State public currentState = State.Funding;

    event Contribution(address indexed contributor, uint256 amount);
    event Payout(address indexed beneficiary, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);

    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        fundingGoal = _fundingGoal * 1 ether; // Goal in Ether
        deadline = block.timestamp + (_durationInDays * 1 days);
        beneficiary = msg.sender;
    }

    function contribute() public payable {
        require(currentState == State.Funding, "Campaign is not in funding state.");
        require(block.timestamp < deadline, "Campaign has ended.");
        
        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function checkGoalReached() public {
        require(block.timestamp >= deadline, "Campaign has not ended yet.");
        
        if (amountRaised >= fundingGoal) {
            currentState = State.Succeeded;
        } else {
            currentState = State.Failed;
        }
    }

    function withdraw() public {
        require(currentState == State.Succeeded, "Campaign did not succeed.");
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw.");
        
        uint256 amount = address(this).balance;
        emit Payout(beneficiary, amount);
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function getRefund() public {
        require(currentState == State.Failed, "Campaign did not fail.");
        uint256 amountToRefund = contributions[msg.sender];
        require(amountToRefund > 0, "No contribution to refund.");

        contributions[msg.sender] = 0;
        emit Refund(msg.sender, amountToRefund);
        (bool success, ) = msg.sender.call{value: amountToRefund}("");
        require(success, "Refund failed.");
    }
}
