// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CrowdFunding
 * @dev A simple crowdfunding contract where users can contribute ETH towards a funding goal.
 * If the goal is not met by the deadline, contributors can get a refund.
 */
contract CrowdFunding {
    address public immutable beneficiary;
    uint256 public immutable fundingGoal;
    uint256 public immutable deadline;

    uint256 public amountRaised;
    mapping(address => uint256) public contributions;

    bool public fundingGoalReached = false;
    bool public campaignClosed = false;

    /**
     * @dev Emitted when a contribution is made.
     * @param contributor The address of the contributor.
     * @param amount The amount contributed in wei.
     */
    event Contribution(address indexed contributor, uint256 amount);

    /**
     * @dev Emitted when the beneficiary withdraws the funds.
     * @param beneficiary The address of the beneficiary.
     * @param amount The total amount withdrawn.
     */
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);

    /**
     * @dev Emitted when a contributor receives a refund.
     * @param contributor The address of the contributor.
     * @param amount The amount refunded.
     */
    event RefundIssued(address indexed contributor, uint256 amount);

    /**
     * @dev Modifier to check if the campaign is still active.
     */
    modifier campaignIsActive() {
        require(!campaignClosed, "Campaign is closed.");
        require(block.timestamp < deadline, "Campaign has ended.");
        _;
    }

    /**
     * @dev Sets up the crowdfunding campaign.
     * @param _fundingGoal The target amount in wei.
     * @param _durationInSeconds The duration of the campaign in seconds.
     * @param _beneficiary The address that will receive the funds if the goal is met.
     */
    constructor(uint256 _fundingGoal, uint256 _durationInSeconds, address _beneficiary) {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address.");
        
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _durationInSeconds;
        beneficiary = _beneficiary;
    }

    /**
     * @dev Allows users to contribute ETH to the campaign.
     */
    function contribute() public payable campaignIsActive {
        require(msg.value > 0, "Contribution must be greater than zero.");
        
        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;

        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
        }

        emit Contribution(msg.sender, msg.value);
    }

    /**
     * @dev Allows the beneficiary to withdraw the funds if the goal has been reached.
     * Can be called at any time after the goal is met.
     */
    function withdraw() public {
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw funds.");
        require(fundingGoalReached, "Funding goal has not been reached.");
        require(!campaignClosed, "Campaign is already closed.");

        campaignClosed = true;
        uint256 amount = address(this).balance;
        
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit FundsWithdrawn(beneficiary, amount);
    }

    /**
     * @dev Allows contributors to get a refund if the funding goal was not met by the deadline.
     */
    function claimRefund() public {
        require(block.timestamp >= deadline, "Campaign has not ended yet.");
        require(!fundingGoalReached, "Funding goal was reached, no refunds.");
        
        uint256 amountToRefund = contributions[msg.sender];
        require(amountToRefund > 0, "You have no contribution to refund.");

        contributions[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToRefund}("");
        require(success, "Refund failed.");

        emit RefundIssued(msg.sender, amountToRefund);
    }

    /**
     * @dev Returns the current state of the contract balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
