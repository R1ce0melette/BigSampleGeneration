// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalRaised;
    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event ProjectFunded(uint256 totalRaised);
    event Refund(address indexed contributor, uint256 amount);

    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        owner = msg.sender;
        fundingGoal = _fundingGoal * 1 ether;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Funding period has ended.");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(block.timestamp >= deadline, "Funding period has not ended yet.");
        require(totalRaised >= fundingGoal, "Funding goal not reached.");
        
        emit ProjectFunded(totalRaised);
        payable(owner).transfer(address(this).balance);
    }

    function getRefund() public {
        require(block.timestamp >= deadline, "Funding period has not ended yet.");
        require(totalRaised < fundingGoal, "Funding goal was reached.");
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
