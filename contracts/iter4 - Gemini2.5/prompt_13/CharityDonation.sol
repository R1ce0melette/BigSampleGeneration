// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityDonation {
    address public owner;
    uint256 public totalDonations;

    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public allDonations;

    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than zero.");
        
        allDonations.push(Donation(msg.sender, msg.value, block.timestamp));
        totalDonations += msg.value;

        emit Donated(msg.sender, msg.value);
    }

    function withdrawDonations() public {
        require(msg.sender == owner, "Only the owner can withdraw donations.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No donations to withdraw.");

        emit Withdrawn(owner, balance);
        payable(owner).transfer(balance);
    }

    function getDonationCount() public view returns (uint256) {
        return allDonations.length;
    }

    function getDonation(uint256 _index) public view returns (address, uint256, uint256) {
        require(_index < allDonations.length, "Donation index out of bounds.");
        Donation storage donationItem = allDonations[_index];
        return (donationItem.donor, donationItem.amount, donationItem.timestamp);
    }
}
