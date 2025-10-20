// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CharityDonations is Ownable {
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public allDonations;
    uint256 public totalDonated;

    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Allows anyone to make a donation in ETH.
     */
    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than zero.");

        allDonations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        totalDonated += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw the collected donations to a specified address.
     * @param _recipient The address to receive the withdrawn funds.
     */
    function withdrawDonations(address payable _recipient) public onlyOwner {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No donations to withdraw.");

        emit Withdrawn(_recipient, balance);
        _recipient.transfer(balance);
    }

    /**
     * @dev Retrieves a specific donation by its index.
     * @param _index The index of the donation in the allDonations array.
     * @return The donor's address, the donation amount, and the timestamp.
     */
    function getDonation(uint256 _index) public view returns (address, uint256, uint256) {
        require(_index < allDonations.length, "Donation index out of bounds.");
        Donation storage donationItem = allDonations[_index];
        return (donationItem.donor, donationItem.amount, donationItem.timestamp);
    }

    /**
     * @dev Returns the total number of donations made.
     * @return The total count of donations.
     */
    function getDonationCount() public view returns (uint256) {
        return allDonations.length;
    }
}
