// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationTracker {
    address public owner;
    uint256 public totalDonations;

    struct Donation {
        address from;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public donations;

    event Donated(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than zero.");
        donations.push(Donation(msg.sender, msg.value, block.timestamp));
        totalDonations += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    function getDonationCount() public view returns (uint256) {
        return donations.length;
    }

    function getDonation(uint256 _index) public view returns (address, uint256, uint256) {
        require(_index < donations.length, "Index out of bounds.");
        Donation storage donation = donations[_index];
        return (donation.from, donation.amount, donation.timestamp);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        
        payable(owner).transfer(balance);
        emit Withdrawn(owner, balance);
    }
}
