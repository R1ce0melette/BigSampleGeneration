// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CharityDonationTracker
 * @dev A contract to track donations for a charity, making all transactions transparent.
 */
contract CharityDonationTracker {
    // Address of the charity that will receive the donations.
    address public immutable charityAddress;
    // The total amount of ETH donated to the charity.
    uint256 public totalDonations;

    // Structure to represent a single donation.
    struct Donation {
        uint256 id;
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    // An array to store all donation records.
    Donation[] public allDonations;
    // A counter for generating unique donation IDs.
    uint256 private nextDonationId;

    /**
     * @dev Event emitted when a new donation is made.
     * @param donationId The unique ID of the donation.
     * @param donor The address of the donor.
     * @param amount The amount of ETH donated.
     * @param timestamp The time of the donation.
     */
    event Donated(
        uint256 indexed donationId,
        address indexed donor,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Sets the charity's address upon deployment.
     * @param _charityAddress The address of the charity to receive donations.
     */
    constructor(address _charityAddress) {
        require(_charityAddress != address(0), "Charity address cannot be the zero address.");
        charityAddress = _charityAddress;
    }

    /**
     * @dev Allows anyone to donate ETH to the charity.
     * The donated amount is immediately transferred to the charity's address.
     */
    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than zero.");

        // Record the donation
        uint256 donationId = nextDonationId;
        allDonations.push(Donation({
            id: donationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        totalDonations += msg.value;
        nextDonationId++;

        // Emit the donation event
        emit Donated(donationId, msg.sender, msg.value, block.timestamp);

        // Transfer the donation to the charity address
        (bool sent, ) = charityAddress.call{value: msg.value}("");
        require(sent, "Failed to send donation to the charity.");
    }

    /**
     * @dev Retrieves a specific donation by its ID.
     * @param _donationId The ID of the donation to retrieve.
     * @return A tuple containing the donation details: ID, donor, amount, and timestamp.
     */
    function getDonation(uint256 _donationId) public view returns (uint256, address, uint256, uint256) {
        require(_donationId < allDonations.length, "Donation with this ID does not exist.");
        
        Donation storage donation = allDonations[_donationId];
        return (donation.id, donation.donor, donation.amount, donation.timestamp);
    }

    /**
     * @dev Returns the total number of donations made.
     * @return The total count of donations.
     */
    function getDonationCount() public view returns (uint256) {
        return allDonations.length;
    }
}
