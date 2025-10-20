// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalContributed;
    mapping(address => uint256) public contributions;
    bool public goalReached;
    bool public refunded;

    constructor(uint256 _goal, uint256 _duration) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }

    function contribute() external payable {
        require(block.timestamp < deadline, "Campaign ended");
        require(!goalReached, "Goal already reached");
        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;
        if (totalContributed >= goal) {
            goalReached = true;
        }
    }

    function claimFunds() external {
        require(msg.sender == owner, "Only owner");
        require(goalReached, "Goal not reached");
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
    }
}
