// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalContributed;
    bool public goalReached;
    bool public refunded;

    mapping(address => uint256) public contributions;

    event Contributed(address indexed user, uint256 amount);
    event Refunded(address indexed user, uint256 amount);
    event GoalReached(uint256 totalAmount);

    constructor(uint256 _goal, uint256 _duration) {
        require(_goal > 0, "Goal must be positive");
        require(_duration > 0, "Duration must be positive");
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }

    function contribute() external payable {
        require(block.timestamp < deadline, "Campaign ended");
        require(msg.value > 0, "Must send ETH");
        require(!goalReached, "Goal already reached");
        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;
        emit Contributed(msg.sender, msg.value);
        if (totalContributed >= goal) {
            goalReached = true;
            emit GoalReached(totalContributed);
        }
    }

    function claimRefund() external {
        require(block.timestamp >= deadline, "Campaign not ended");
        require(!goalReached, "Goal was reached");
        require(contributions[msg.sender] > 0, "No contribution");
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refunded(msg.sender, amount);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        require(goalReached, "Goal not reached");
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds");
        payable(owner).transfer(amount);
    }
}
