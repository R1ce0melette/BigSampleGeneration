// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CrowdFund
 * @dev A contract for a simple crowdfunding project.
 */
contract CrowdFund {
    // Address of the project creator who can withdraw the funds.
    address public immutable beneficiary;
    // The total funding goal in wei.
    uint256 public immutable fundingGoal;
    // The timestamp after which the campaign ends.
    uint256 public immutable deadline;

    // The total amount raised so far.
    uint256 public amountRaised;
    // Mapping from contributor address to their contributed amount.
    mapping(address => uint256) public contributions;

    // State to track if the campaign has been finalized.
    bool private campaignFinished;

    /**
     * @dev Event emitted when a contribution is made.
     * @param contributor The address of the contributor.
     * @param amount The amount contributed in wei.
     */
    event Contribution(address indexed contributor, uint256 amount);

    /**
     * @dev Event emitted when the beneficiary withdraws the funds.
     * @param beneficiaryAddress The address of the beneficiary.
     * @param amount The total amount withdrawn.
     */
    event FundsWithdrawn(address indexed beneficiaryAddress, uint256 amount);

    /**
     * @dev Event emitted when a contributor receives a refund.
     * @param contributor The address of the contributor.
     * @param amount The amount refunded.
     */
    event RefundIssued(address indexed contributor, uint256 amount);

    /**
     * @dev Modifier to ensure the campaign has not ended yet.
     */
    modifier campaignIsActive() {
        require(block.timestamp < deadline, "Campaign has ended.");
        _;
    }

    /**
     * @dev Sets up the crowdfunding campaign.
     * @param _beneficiary The address to receive the funds if the goal is met.
     * @param _fundingGoal The target amount to raise.
     * @param _durationInSeconds The duration of the campaign in seconds.
     */
    constructor(address _beneficiary, uint256 _fundingGoal, uint256 _durationInSeconds) {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(_durationInSeconds > 0, "Duration must be greater than zero.");
        
        beneficiary = _beneficiary;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _durationInSeconds;
    }

    /**
     * @dev Allows users to contribute ETH to the campaign.
     */
    function contribute() public payable campaignIsActive {
        require(msg.value > 0, "Contribution must be greater than zero.");
        
        contributions[msg.sender] += msg.value;
        amountRaised += msg.value;
        
        emit Contribution(msg.sender, msg.value);
    }

    /**
     * @dev Called by anyone after the deadline to finalize the campaign.
     * This function determines if the campaign was successful or failed.
     */
    function finalizeCampaign() public {
        require(block.timestamp >= deadline, "Campaign is still active.");
        require(!campaignFinished, "Campaign has already been finalized.");

        campaignFinished = true;
        // If goal is met, funds are withdrawable by beneficiary.
        // If not, contributors can claim a refund.
    }

    /**
     * @dev Allows the beneficiary to withdraw the funds if the goal was met.
     */
    function withdraw() public {
        require(beneficiary == msg.sender, "Only the beneficiary can withdraw.");
        require(block.timestamp >= deadline, "Campaign is still active.");
        require(amountRaised >= fundingGoal, "Funding goal was not met.");

        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw.");

        emit FundsWithdrawn(beneficiary, amount);

        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Fund transfer failed.");
    }

    /**
     * @dev Allows contributors to get a refund if the funding goal was not met.
     */
    function refund() public {
        require(block.timestamp >= deadline, "Campaign is still active.");
        require(amountRaised < fundingGoal, "Funding goal was met, no refunds.");

        uint256 contributionAmount = contributions[msg.sender];
        require(contributionAmount > 0, "You have no contribution to refund.");

        contributions[msg.sender] = 0;
        emit RefundIssued(msg.sender, contributionAmount);

        (bool success, ) = msg.sender.call{value: contributionAmount}("");
        require(success, "Refund transfer failed.");
    }

    /**
     * @dev Returns the current state of the campaign.
     * @return A string indicating if the campaign is "Active", "Successful", or "Failed".
     */
    function getCampaignState() public view returns (string memory) {
        if (block.timestamp < deadline) {
            return "Active";
        }
        if (amountRaised >= fundingGoal) {
            return "Successful";
        }
        return "Failed";
    }
}
