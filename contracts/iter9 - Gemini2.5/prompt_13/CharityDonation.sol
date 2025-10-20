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

    Donation[] public donations;

    event Donated(address indexed donor, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than zero.");

        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        totalDonations += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    function getDonationCount() public view returns (uint256) {
        return donations.length;
    }

    function getDonation(uint256 _index) public view returns (address, uint256, uint256) {
        require(_index < donations.length, "Donation index out of bounds.");
        Donation storage donation = donations[_index];
        return (donation.donor, donation.amount, donation.timestamp);
    }

    function withdraw(address payable _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "Recipient address cannot be the zero address.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient funds in the contract.");

        _recipient.transfer(_amount);
        emit Withdrawn(_recipient, _amount);
    }
}
