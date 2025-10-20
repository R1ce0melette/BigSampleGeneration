// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleCrowdfund
 * @dev A basic crowdfunding contract where users can contribute ETH towards a goal.
 * If the goal is not met by the deadline, contributors can get a refund.
 */
contract SimpleCrowdfund {
    // The address of the project creator
    address public immutable owner;

    // The funding goal in wei
    uint256 public immutable goal;

    // The timestamp after which the campaign ends
    uint256 public immutable deadline;

    // Total amount raised
    uint256 public raisedAmount;

    // Mapping to track contributions from each address
    mapping(address => uint256) public contributions;

    // State of the campaign
    bool public goalReached = false;
    bool public campaignClosed = false;

    /**
     * @dev Emitted when a contribution is made.
     * @param contributor The address of the contributor.
     * @param amount The amount contributed in wei.
     */
    event Contribution(address indexed contributor, uint256 amount);

    /**
     * @dev Emitted when the owner withdraws the funds.
     * @param recipient The address receiving the funds.
     * @param amount The amount withdrawn in wei.
     */
    event Withdrawal(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when a contributor gets a refund.
     * @param contributor The address of the contributor receiving the refund.
     * @param amount The amount refunded in wei.
     */
    event Refund(address indexed contributor, uint256 amount);

    /**
     * @dev Sets up the crowdfunding campaign.
     * @param _goal The funding goal in ETH.
     * @param _durationInDays The duration of the campaign in days.
     */
    constructor(uint256 _goal, uint256 _durationInDays) {
        require(_goal > 0, "Goal must be greater than 0");
        owner = msg.sender;
        goal = _goal * 1 ether; // Convert ETH to wei
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    /**
     * @dev Allows users to contribute ETH to the campaign.
     */
    function contribute() public payable {
        require(block.timestamp < deadline, "Campaign has ended.");
        require(!campaignClosed, "Campaign is closed.");
        require(msg.value > 0, "Contribution must be greater than 0.");

        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;

        if (raisedAmount >= goal) {
            goalReached = true;
        }

        emit Contribution(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw the funds if the goal has been reached.
     */
    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw.");
        require(goalReached, "Funding goal not reached.");
        require(!campaignClosed, "Campaign is already closed.");

        campaignClosed = true;
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
        require(!goalReached, "Funding goal was reached.");

        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution to refund.");

        contributions[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund failed.");

        emit Refund(msg.sender, amount);
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
