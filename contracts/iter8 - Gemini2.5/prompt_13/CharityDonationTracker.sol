// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CharityDonationTracker
 * @dev A contract to track donations for a charity. All donations and total amounts are publicly visible.
 */
contract CharityDonationTracker {
    address public owner;
    uint256 public totalDonations;

    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public donations;

    event DonationReceived(address indexed donor, uint256 amount, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows anyone to donate ETH to the charity.
     */
    function donate() external payable {
        require(msg.value > 0, "Donation must be greater than zero.");

        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        totalDonations += msg.value;

        emit DonationReceived(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Allows the owner to withdraw the collected funds.
     * @param _to The address to send the funds to.
     */
    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "Invalid address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Returns the total number of donations made.
     * @return The count of donations.
     */
    function getDonationCount() external view returns (uint256) {
        return donations.length;
    }
}
