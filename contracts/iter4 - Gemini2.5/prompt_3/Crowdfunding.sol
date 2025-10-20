// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address payable public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public raisedAmount;
    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);

    constructor(uint256 _fundingGoal, uint256 _durationInSeconds) {
        owner = payable(msg.sender);
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _durationInSeconds;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Campaign has ended.");
        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw.");
        require(raisedAmount >= fundingGoal, "Funding goal not reached.");
        emit Withdrawal(owner, raisedAmount);
        owner.transfer(raisedAmount);
    }

    function refund() public {
        require(block.timestamp >= deadline, "Campaign is still active.");
        require(raisedAmount < fundingGoal, "Funding goal was reached.");
        uint256 amountToRefund = contributions[msg.sender];
        require(amountToRefund > 0, "No contribution to refund.");
        
        contributions[msg.sender] = 0;
        emit Refund(msg.sender, amountToRefund);
        payable(msg.sender).transfer(amountToRefund);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
