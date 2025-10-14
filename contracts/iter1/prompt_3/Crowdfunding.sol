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

    event Contributed(address indexed contributor, uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);

    constructor(uint256 _goal, uint256 _duration) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }

    function contribute() external payable {
        require(block.timestamp < deadline, "Campaign ended");
        require(msg.value > 0, "No ETH sent");
        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;
        emit Contributed(msg.sender, msg.value);
        if (totalContributed >= goal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalContributed);
        }
    }

    function claimFunds() external {
        require(msg.sender == owner, "Not owner");
        require(goalReached, "Goal not reached");
        require(address(this).balance > 0, "No funds");
        payable(owner).transfer(address(this).balance);
    }

    function refund() external {
        require(block.timestamp >= deadline, "Campaign not ended");
        require(!goalReached, "Goal was reached");
        require(!refunded, "Already refunded");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution");
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refunded(msg.sender, amount);
    }

    function markRefunded() external {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp >= deadline, "Campaign not ended");
        require(!goalReached, "Goal was reached");
        refunded = true;
    }
}
