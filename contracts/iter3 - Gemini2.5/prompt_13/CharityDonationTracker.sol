// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CharityDonationTracker
 * @dev A contract to track and manage donations for a charity.
 * All donations are transparent and visible on-chain.
 */
contract CharityDonationTracker {
    struct Donation {
        uint256 id;
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    address public owner;
    address payable public charityWallet;
    uint256 public totalDonations;
    uint256 private _donationIdCounter;

    // An array to store all donation records
    Donation[] public allDonations;

    /**
     * @dev Emitted when a new donation is made.
     * @param donationId The unique ID of the donation.
     * @param donor The address of the donor.
     * @param amount The amount donated in wei.
     */
    event Donated(
        uint256 indexed donationId,
        address indexed donor,
        uint256 amount
    );

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets up the contract with the charity's wallet address.
     * @param _charityWallet The address where donations will be sent.
     */
    constructor(address payable _charityWallet) {
        require(_charityWallet != address(0), "Charity wallet cannot be the zero address.");
        owner = msg.sender;
        charityWallet = _charityWallet;
    }

    /**
     * @dev Allows anyone to make a donation.
     * The donated amount is immediately transferred to the charity wallet.
     */
    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than zero.");

        _donationIdCounter++;
        uint256 newDonationId = _donationIdCounter;
        
        Donation memory newDonation = Donation({
            id: newDonationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        allDonations.push(newDonation);
        totalDonations += msg.value;

        // Transfer the donation to the charity wallet
        (bool success, ) = charityWallet.call{value: msg.value}("");
        require(success, "Failed to send donation to the charity wallet.");

        emit Donated(newDonationId, msg.sender, msg.value);
    }

    /**
     * @dev Retrieves a specific donation by its ID.
     * @param _donationId The ID of the donation to retrieve.
     * @return A tuple containing the donation details: ID, donor, amount, and timestamp.
     */
    function getDonationById(uint256 _donationId) public view returns (uint256, address, uint256, uint256) {
        require(_donationId > 0 && _donationId <= allDonations.length, "Donation ID is out of bounds.");
        Donation storage donation = allDonations[_donationId - 1];
        return (donation.id, donation.donor, donation.amount, donation.timestamp);
    }

    /**
     * @dev Returns the total number of donations made.
     * @return The total count of donations.
     */
    function getTotalDonationCount() public view returns (uint256) {
        return allDonations.length;
    }

    /**
     * @dev Allows the owner to update the charity wallet address.
     * @param _newCharityWallet The new address for the charity wallet.
     */
    function setCharityWallet(address payable _newCharityWallet) public onlyOwner {
        require(_newCharityWallet != address(0), "New charity wallet cannot be the zero address.");
        charityWallet = _newCharityWallet;
    }
}
