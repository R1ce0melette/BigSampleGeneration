// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityTracker {
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
        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        totalDonated += msg.value;
        emit Donated(msg.sender, msg.value, block.timestamp);
    }

    function getDonation(uint256 index) external view returns (address, uint256, uint256) {
        require(index < donations.length, "Invalid index");
        Donation storage d = donations[index];
        return (d.donor, d.amount, d.timestamp);
    }

    function getDonationCount() external view returns (uint256) {
        return donations.length;
    }
}
