// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityDonations {
    address public owner;
    uint256 public totalDonations;

    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public donations;

    event Donated(address indexed donor, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than zero.");
        
        donations.push(Donation(msg.sender, msg.value, block.timestamp));
        totalDonations += msg.value;

        emit Donated(msg.sender, msg.value, block.timestamp);
    }

    function getDonationCount() public view returns (uint256) {
        return donations.length;
    }

    function getDonation(uint256 _index) public view returns (address, uint256, uint256) {
        require(_index < donations.length, "Donation index out of bounds.");
        Donation storage donationData = donations[_index];
        return (donationData.donor, donationData.amount, donationData.timestamp);
    }

    function withdraw(address payable _recipient, uint256 _amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(_amount <= address(this).balance, "Insufficient funds in contract.");
        
        _recipient.transfer(_amount);
        
        emit Withdrawn(_recipient, _amount);
    }
}
