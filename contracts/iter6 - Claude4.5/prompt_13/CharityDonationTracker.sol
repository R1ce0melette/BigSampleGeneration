// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CharityDonationTracker
 * @dev A contract for tracking charity donations where all donations and total amounts are visible on-chain
 */
contract CharityDonationTracker {
    address public charityOwner;
    
    struct Donation {
        uint256 id;
        address donor;
        uint256 amount;
        uint256 timestamp;
        string message;
    }
    
    uint256 public donationCount;
    uint256 public totalDonations;
    
    mapping(uint256 => Donation) public donations;
    mapping(address => uint256) public donorTotalAmount;
    mapping(address => uint256[]) public donorDonationIds;
    
    // Events
    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed charityOwner, uint256 amount, uint256 timestamp);
    
    constructor() {
        charityOwner = msg.sender;
    }
    
    /**
     * @dev Make a donation to the charity
     * @param message Optional message with the donation
     */
    function donate(string memory message) external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        totalDonations += msg.value;
        
        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message
        });
        
        donorTotalAmount[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationCount);
        
        emit DonationReceived(donationCount, msg.sender, msg.value, message, block.timestamp);
    }
    
    /**
     * @dev Withdraw funds to the charity owner
     * @param amount The amount to withdraw (0 to withdraw all)
     */
    function withdrawFunds(uint256 amount) external {
        require(msg.sender == charityOwner, "Only charity owner can withdraw");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        uint256 withdrawAmount = amount == 0 ? balance : amount;
        require(withdrawAmount <= balance, "Insufficient balance");
        
        (bool success, ) = charityOwner.call{value: withdrawAmount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(charityOwner, withdrawAmount, block.timestamp);
    }
    
    /**
     * @dev Get donation details by ID
     * @param donationId The ID of the donation
     * @return id The donation ID
     * @return donor The donor's address
     * @return amount The donation amount
     * @return timestamp The donation timestamp
     * @return message The donation message
     */
    function getDonation(uint256 donationId) external view returns (
        uint256 id,
        address donor,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(donationId > 0 && donationId <= donationCount, "Donation does not exist");
        Donation memory donation = donations[donationId];
        
        return (
            donation.id,
            donation.donor,
            donation.amount,
            donation.timestamp,
            donation.message
        );
    }
    
    /**
     * @dev Get all donation IDs for a specific donor
     * @param donor The address of the donor
     * @return Array of donation IDs
     */
    function getDonationsByDonor(address donor) external view returns (uint256[] memory) {
        return donorDonationIds[donor];
    }
    
    /**
     * @dev Get the total amount donated by a specific donor
     * @param donor The address of the donor
     * @return The total amount donated
     */
    function getDonorTotalAmount(address donor) external view returns (uint256) {
        return donorTotalAmount[donor];
    }
    
    /**
     * @dev Get the caller's total donations
     * @return The total amount donated by the caller
     */
    function getMyTotalDonations() external view returns (uint256) {
        return donorTotalAmount[msg.sender];
    }
    
    /**
     * @dev Get the caller's donation IDs
     * @return Array of donation IDs
     */
    function getMyDonations() external view returns (uint256[] memory) {
        return donorDonationIds[msg.sender];
    }
    
    /**
     * @dev Get all donation IDs
     * @return Array of all donation IDs
     */
    function getAllDonationIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](donationCount);
        for (uint256 i = 0; i < donationCount; i++) {
            ids[i] = i + 1;
        }
        return ids;
    }
    
    /**
     * @dev Get the latest N donations
     * @param count The number of recent donations to retrieve
     * @return donationIds Array of the latest donation IDs
     */
    function getLatestDonations(uint256 count) external view returns (uint256[] memory) {
        if (count > donationCount) {
            count = donationCount;
        }
        
        uint256[] memory donationIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            donationIds[i] = donationCount - i;
        }
        
        return donationIds;
    }
    
    /**
     * @dev Get top donors
     * @param count Maximum number of top donors to return
     * @return donors Array of donor addresses
     * @return amounts Array of corresponding donation amounts
     */
    function getTopDonors(uint256 count) external view returns (
        address[] memory donors,
        uint256[] memory amounts
    ) {
        // Create a list of unique donors
        address[] memory uniqueDonors = new address[](donationCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 1; i <= donationCount; i++) {
            address donor = donations[i].donor;
            bool exists = false;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueDonors[j] == donor) {
                    exists = true;
                    break;
                }
            }
            
            if (!exists) {
                uniqueDonors[uniqueCount] = donor;
                uniqueCount++;
            }
        }
        
        // Limit count to actual number of unique donors
        if (count > uniqueCount) {
            count = uniqueCount;
        }
        
        // Simple selection sort to find top donors
        donors = new address[](count);
        amounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            uint256 maxAmount = 0;
            address maxDonor = address(0);
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (donorTotalAmount[uniqueDonors[j]] > maxAmount) {
                    maxAmount = donorTotalAmount[uniqueDonors[j]];
                    maxDonor = uniqueDonors[j];
                    maxIndex = j;
                }
            }
            
            donors[i] = maxDonor;
            amounts[i] = maxAmount;
            
            // Remove this donor from consideration
            uniqueDonors[maxIndex] = uniqueDonors[uniqueCount - 1];
            uniqueCount--;
        }
        
        return (donors, amounts);
    }
    
    /**
     * @dev Get charity statistics
     * @return _totalDonations Total amount donated
     * @return _donationCount Total number of donations
     * @return _contractBalance Current contract balance
     * @return _uniqueDonors Approximate number of unique donors
     */
    function getStats() external view returns (
        uint256 _totalDonations,
        uint256 _donationCount,
        uint256 _contractBalance,
        uint256 _uniqueDonors
    ) {
        // Count unique donors
        address[] memory uniqueDonors = new address[](donationCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 1; i <= donationCount; i++) {
            address donor = donations[i].donor;
            bool exists = false;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueDonors[j] == donor) {
                    exists = true;
                    break;
                }
            }
            
            if (!exists) {
                uniqueDonors[uniqueCount] = donor;
                uniqueCount++;
            }
        }
        
        return (
            totalDonations,
            donationCount,
            address(this).balance,
            uniqueCount
        );
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer charity ownership
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external {
        require(msg.sender == charityOwner, "Only charity owner can transfer ownership");
        require(newOwner != address(0), "New owner cannot be zero address");
        
        charityOwner = newOwner;
    }
}
