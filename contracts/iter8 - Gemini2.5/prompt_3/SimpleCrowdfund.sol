// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleCrowdfund
 * @dev A basic crowdfunding contract where users can contribute ETH towards a goal.
 * If the goal is not met by the deadline, contributors can claim a refund.
 */
contract SimpleCrowdfund {
    address public immutable owner;
    uint256 public immutable goal; // in wei
    uint256 public immutable deadline;
    uint256 public raisedAmount;
    mapping(address => uint256) public contributions;
    bool public isGoalReached;

    event Contribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);

    /**
     * @dev Sets up the crowdfunding campaign.
     * @param _goalInEth The funding goal in Ether.
     * @param _durationInDays The duration of the campaign in days.
     */
    constructor(uint256 _goalInEth, uint256 _durationInDays) {
        require(_goalInEth > 0, "Goal must be greater than 0");
        owner = msg.sender;
        goal = _goalInEth * 1 ether;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    /**
     * @dev Allows users to contribute ETH to the campaign.
     */
    function contribute() public payable {
        require(block.timestamp < deadline, "Campaign has ended.");
        require(msg.value > 0, "Contribution must be greater than 0.");

        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;

        if (raisedAmount >= goal) {
            isGoalReached = true;
        }

        emit Contribution(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw the funds if the goal has been reached.
     */
    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw.");
        require(isGoalReached, "Funding goal not reached.");
        
        uint256 amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit Withdrawal(owner, amount);
    }

    /**
     * @dev Allows contributors to get a refund if the campaign has ended and the goal was not met.
     */
    function getRefund() public {
        require(block.timestamp >= deadline, "Campaign is still active.");
        require(!isGoalReached, "Funding goal was reached, no refunds.");

        uint256 amountToRefund = contributions[msg.sender];
        require(amountToRefund > 0, "No contribution to refund.");

        contributions[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToRefund}("");
        require(success, "Refund failed.");

        emit Refund(msg.sender, amountToRefund);
    }

    /**
     * @dev Returns the remaining time for the campaign in seconds.
     * @return The time remaining.
     */
    function getTimeRemaining() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}
