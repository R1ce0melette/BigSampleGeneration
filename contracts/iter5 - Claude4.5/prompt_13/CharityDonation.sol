// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityDonation {
    address public owner;
    uint256 public totalDonations;
    uint256 public donationCount;
    
    struct Donation {
        uint256 id;
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    mapping(uint256 => Donation) public donations;
    mapping(address => uint256) public donorTotalDonations;
    mapping(address => uint256[]) public donorDonationIds;
    
    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount, string purpose);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function donate(string memory _message) external payable {
        require(msg.value > 0, "Donation must be greater than zero");
        
        donationCount++;
        
        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        });
        
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationCount);
        
        emit DonationReceived(donationCount, msg.sender, msg.value, _message, block.timestamp);
    }
    
    function getDonation(uint256 _donationId) external view returns (
        uint256 id,
        address donor,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(_donationId > 0 && _donationId <= donationCount, "Donation does not exist");
        
        Donation memory donation = donations[_donationId];
        
        return (
            donation.id,
            donation.donor,
            donation.amount,
            donation.message,
            donation.timestamp
        );
    }
    
    function getDonorDonations(address _donor) external view returns (uint256[] memory) {
        return donorDonationIds[_donor];
    }
    
    function getDonorTotalDonation(address _donor) external view returns (uint256) {
        return donorTotalDonations[_donor];
    }
    
    function getAllDonations() external view returns (Donation[] memory) {
        Donation[] memory allDonations = new Donation[](donationCount);
        
        for (uint256 i = 1; i <= donationCount; i++) {
            allDonations[i - 1] = donations[i];
        }
        
        return allDonations;
    }
    
    function getRecentDonations(uint256 _count) external view returns (Donation[] memory) {
        uint256 count = _count;
        if (count > donationCount) {
            count = donationCount;
        }
        
        Donation[] memory recentDonations = new Donation[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentDonations[i] = donations[donationCount - i];
        }
        
        return recentDonations;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawFunds(uint256 _amount, string memory _purpose) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= address(this).balance, "Insufficient balance");
        require(bytes(_purpose).length > 0, "Purpose cannot be empty");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, _amount, _purpose);
    }
    
    function withdrawAllFunds(string memory _purpose) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        require(bytes(_purpose).length > 0, "Purpose cannot be empty");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance, _purpose);
    }
    
    receive() external payable {
        donationCount++;
        
        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            message: "Anonymous donation",
            timestamp: block.timestamp
        });
        
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationCount);
        
        emit DonationReceived(donationCount, msg.sender, msg.value, "Anonymous donation", block.timestamp);
    }
}
