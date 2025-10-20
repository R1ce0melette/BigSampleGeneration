// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CharityDonationTracker
 * @dev A contract to track donations for a charity. All donations are public and transparent.
 */
contract CharityDonationTracker {
    // The address of the charity that will receive the donations.
    address public immutable charityAddress;

    // The total amount of Ether donated.
    uint256 public totalDonations;

    // Struct to represent a single donation.
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    // An array to store all donation records.
    Donation[] public allDonations;

    /**
     * @dev Emitted when a new donation is made.
     * @param donor The address of the donor.
     * @param amount The amount of Ether donated.
     */
    event Donated(address indexed donor, uint256 amount);

    /**
     * @dev Sets the charity address when the contract is deployed.
     * @param _charityAddress The address of the charity.
     */
    constructor(address _charityAddress) {
        require(_charityAddress != address(0), "Charity address cannot be the zero address.");
        charityAddress = _charityAddress;
    }

    /**
     * @dev Allows anyone to make a donation.
     * The sent Ether is immediately forwarded to the charity address.
     */
    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than zero.");

        // Add the donation to the records.
        allDonations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        // Update the total donations amount.
        totalDonations += msg.value;

        // Forward the Ether to the charity address.
        (bool success, ) = charityAddress.call{value: msg.value}("");
        require(success, "Failed to send donation to the charity.");

        emit Donated(msg.sender, msg.value);
    }

    /**
     * @dev Returns the total number of donations made.
     * @return The count of all donations.
     */
    function getDonationCount() public view returns (uint256) {
        return allDonations.length;
    }

    /**
     * @dev Retrieves a specific donation by its index.
     * @param _index The index of the donation in the `allDonations` array.
     * @return The donor's address, the amount, and the timestamp of the donation.
     */
    function getDonation(uint256 _index) public view returns (address, uint256, uint256) {
        require(_index < allDonations.length, "Index out of bounds.");
        Donation storage donationItem = allDonations[_index];
        return (donationItem.donor, donationItem.amount, donationItem.timestamp);
    }
}
