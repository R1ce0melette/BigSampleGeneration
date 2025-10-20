// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CharityDonationTracker
 * @dev A contract for tracking charity donations where all donations and total amounts are visible on-chain
 */
contract CharityDonationTracker {
    address public charityOwner;
    
    // Donation structure
    struct Donation {
        uint256 id;
        address donor;
        uint256 amount;
        uint256 timestamp;
        string message;
    }
    
    // State variables
    uint256 public donationCount;
    uint256 public totalDonations;
    mapping(uint256 => Donation) public donations;
    mapping(address => uint256) public donorTotalDonations;
    mapping(address => uint256[]) public donorDonationIds;
    
    // Leaderboard (top donors)
    address[] public donors;
    mapping(address => bool) public isDonor;
    
    // Events
    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, uint256 timestamp);
    event FundsWithdrawn(address indexed charity, uint256 amount);
    event CharityOwnerChanged(address indexed oldOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyCharityOwner() {
        require(msg.sender == charityOwner, "Only charity owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor sets the charity owner
     */
    constructor() {
        charityOwner = msg.sender;
    }
    
    /**
     * @dev Donate to the charity
     * @param message Optional message with the donation
     */
    function donate(string memory message) external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        uint256 donationId = donationCount;
        
        donations[donationId] = Donation({
            id: donationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message
        });
        
        // Update totals
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationId);
        
        // Track unique donors
        if (!isDonor[msg.sender]) {
            isDonor[msg.sender] = true;
            donors.push(msg.sender);
        }
        
        emit DonationReceived(donationId, msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Donate without a message
     */
    function donate() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        uint256 donationId = donationCount;
        
        donations[donationId] = Donation({
            id: donationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        });
        
        // Update totals
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationId);
        
        // Track unique donors
        if (!isDonor[msg.sender]) {
            isDonor[msg.sender] = true;
            donors.push(msg.sender);
        }
        
        emit DonationReceived(donationId, msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Get donation details
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
        require(donationId > 0 && donationId <= donationCount, "Invalid donation ID");
        
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
     * @dev Get all donation IDs from a specific donor
     * @param donor The donor's address
     * @return Array of donation IDs
     */
    function getDonorDonations(address donor) external view returns (uint256[] memory) {
        return donorDonationIds[donor];
    }
    
    /**
     * @dev Get total donations from a specific donor
     * @param donor The donor's address
     * @return The total amount donated by the donor
     */
    function getDonorTotal(address donor) external view returns (uint256) {
        return donorTotalDonations[donor];
    }
    
    /**
     * @dev Get recent donations
     * @param count The number of recent donations to retrieve
     * @return Array of recent donations
     */
    function getRecentDonations(uint256 count) external view returns (Donation[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 actualCount = count > donationCount ? donationCount : count;
        Donation[] memory recentDonations = new Donation[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            recentDonations[i] = donations[donationCount - i];
        }
        
        return recentDonations;
    }
    
    /**
     * @dev Get all donations (WARNING: may be gas-intensive for large datasets)
     * @return Array of all donations
     */
    function getAllDonations() external view returns (Donation[] memory) {
        Donation[] memory allDonations = new Donation[](donationCount);
        
        for (uint256 i = 1; i <= donationCount; i++) {
            allDonations[i - 1] = donations[i];
        }
        
        return allDonations;
    }
    
    /**
     * @dev Get top donors
     * @param count The number of top donors to retrieve
     * @return topDonorAddresses Array of top donor addresses
     * @return topDonorAmounts Array of corresponding donation amounts
     */
    function getTopDonors(uint256 count) external view returns (
        address[] memory topDonorAddresses,
        uint256[] memory topDonorAmounts
    ) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 actualCount = count > donors.length ? donors.length : count;
        
        // Create temporary arrays for sorting
        address[] memory tempAddresses = new address[](donors.length);
        uint256[] memory tempAmounts = new uint256[](donors.length);
        
        for (uint256 i = 0; i < donors.length; i++) {
            tempAddresses[i] = donors[i];
            tempAmounts[i] = donorTotalDonations[donors[i]];
        }
        
        // Simple bubble sort to find top donors
        for (uint256 i = 0; i < donors.length; i++) {
            for (uint256 j = i + 1; j < donors.length; j++) {
                if (tempAmounts[j] > tempAmounts[i]) {
                    // Swap amounts
                    uint256 tempAmount = tempAmounts[i];
                    tempAmounts[i] = tempAmounts[j];
                    tempAmounts[j] = tempAmount;
                    
                    // Swap addresses
                    address tempAddress = tempAddresses[i];
                    tempAddresses[i] = tempAddresses[j];
                    tempAddresses[j] = tempAddress;
                }
            }
        }
        
        // Create result arrays
        topDonorAddresses = new address[](actualCount);
        topDonorAmounts = new uint256[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            topDonorAddresses[i] = tempAddresses[i];
            topDonorAmounts[i] = tempAmounts[i];
        }
        
        return (topDonorAddresses, topDonorAmounts);
    }
    
    /**
     * @dev Get the total number of unique donors
     * @return The number of unique donors
     */
    function getUniqueDonorCount() external view returns (uint256) {
        return donors.length;
    }
    
    /**
     * @dev Get charity statistics
     * @return totalAmount Total amount donated
     * @return donationCount_ Total number of donations
     * @return uniqueDonors Number of unique donors
     * @return contractBalance Current contract balance
     */
    function getCharityStats() external view returns (
        uint256 totalAmount,
        uint256 donationCount_,
        uint256 uniqueDonors,
        uint256 contractBalance
    ) {
        return (
            totalDonations,
            donationCount,
            donors.length,
            address(this).balance
        );
    }
    
    /**
     * @dev Withdraw funds to charity owner (only charity owner)
     * @param amount The amount to withdraw
     */
    function withdrawFunds(uint256 amount) external onlyCharityOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = charityOwner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(charityOwner, amount);
    }
    
    /**
     * @dev Withdraw all funds to charity owner (only charity owner)
     */
    function withdrawAllFunds() external onlyCharityOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = charityOwner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(charityOwner, balance);
    }
    
    /**
     * @dev Transfer charity ownership (only charity owner)
     * @param newOwner The address of the new charity owner
     */
    function transferCharityOwnership(address newOwner) external onlyCharityOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != charityOwner, "New owner is the same as current owner");
        
        address oldOwner = charityOwner;
        charityOwner = newOwner;
        
        emit CharityOwnerChanged(oldOwner, newOwner);
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Fallback function to accept donations
     */
    receive() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        uint256 donationId = donationCount;
        
        donations[donationId] = Donation({
            id: donationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        });
        
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationId);
        
        if (!isDonor[msg.sender]) {
            isDonor[msg.sender] = true;
            donors.push(msg.sender);
        }
        
        emit DonationReceived(donationId, msg.sender, msg.value, block.timestamp);
    }
}
