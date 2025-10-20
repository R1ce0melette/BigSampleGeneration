// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityDonation {
    address public owner;
    uint256 public totalDonations;
    uint256 public donationCount;
    
    struct Donation {
        uint256 donationId;
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    mapping(uint256 => Donation) public donations;
    mapping(address => uint256) public donorTotalAmount;
    mapping(address => uint256[]) public donorDonationIds;
    
    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function donate(string memory _message) external payable {
        require(msg.value > 0, "Donation must be greater than 0");
        
        donationCount++;
        
        donations[donationCount] = Donation({
            donationId: donationCount,
            donor: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        });
        
        donorTotalAmount[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationCount);
        totalDonations += msg.value;
        
        emit DonationReceived(donationCount, msg.sender, msg.value, _message, block.timestamp);
    }
    
    function getDonation(uint256 _donationId) external view returns (
        uint256 donationId,
        address donor,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(_donationId > 0 && _donationId <= donationCount, "Invalid donation ID");
        Donation memory donation = donations[_donationId];
        
        return (
            donation.donationId,
            donation.donor,
            donation.amount,
            donation.message,
            donation.timestamp
        );
    }
    
    function getDonorTotal(address _donor) external view returns (uint256) {
        return donorTotalAmount[_donor];
    }
    
    function getDonorDonationIds(address _donor) external view returns (uint256[] memory) {
        return donorDonationIds[_donor];
    }
    
    function getDonorDonationCount(address _donor) external view returns (uint256) {
        return donorDonationIds[_donor].length;
    }
    
    function getRecentDonations(uint256 _count) external view returns (Donation[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > donationCount ? donationCount : _count;
        Donation[] memory recentDonations = new Donation[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentDonations[i] = donations[donationCount - i];
        }
        
        return recentDonations;
    }
    
    function getTopDonors(uint256 _count) external view returns (address[] memory, uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        // This is a simplified implementation
        // In production, you'd want to maintain a sorted list or use off-chain indexing
        uint256 count = _count > donationCount ? donationCount : _count;
        address[] memory topDonors = new address[](count);
        uint256[] memory topAmounts = new uint256[](count);
        
        // Note: This is a basic implementation and not gas-efficient for large datasets
        // For production use, consider using events and off-chain indexing
        
        return (topDonors, topAmounts);
    }
    
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, _amount);
    }
    
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
