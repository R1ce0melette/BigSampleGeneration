// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityDonationTracker {
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public donations;
    uint256 public totalDonated;

    event Donated(address indexed donor, uint256 amount, uint256 timestamp);

    function donate() external payable {
        require(msg.value > 0, "No ETH sent");
        donations.push(Donation(msg.sender, msg.value, block.timestamp));
        totalDonated += msg.value;
        emit Donated(msg.sender, msg.value, block.timestamp);
    }

    function getDonation(uint256 index) external view returns (address, uint256, uint256) {
        Donation storage d = donations[index];
        return (d.donor, d.amount, d.timestamp);
    }

    function getDonationCount() external view returns (uint256) {
        return donations.length;
    }
}
