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
    uint256 public totalDonationsReceived;
    
    mapping(uint256 => Donation) public donations;
    mapping(address => uint256) public donorTotalAmount;
    mapping(address => uint256[]) public donorDonationIds;
    
    // Events
    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed charity, uint256 amount, uint256 timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == charityOwner, "Only charity owner can call this function");
        _;
    }
    
    constructor() {
        charityOwner = msg.sender;
    }
    
    /**
     * @dev Allows anyone to donate to the charity
     * @param _message Optional message from the donor
     */
    function donate(string memory _message) external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        totalDonationsReceived += msg.value;
        
        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: _message
        });
        
        donorTotalAmount[msg.sender] += msg.value;
        donorDonationIds[msg.sender].push(donationCount);
        
        emit DonationReceived(donationCount, msg.sender, msg.value, _message, block.timestamp);
    }
    
    /**
     * @dev Allows the charity owner to withdraw funds
     * @param _amount The amount to withdraw
     */
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = charityOwner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(charityOwner, _amount, block.timestamp);
    }
    
    /**
     * @dev Allows the charity owner to withdraw all funds
     */
    function withdrawAllFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = charityOwner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(charityOwner, balance, block.timestamp);
    }
    
    /**
     * @dev Returns the details of a specific donation
     * @param _donationId The ID of the donation
     * @return id The donation ID
     * @return donor The donor's address
     * @return amount The donation amount
     * @return timestamp When the donation was made
     * @return message The donor's message
     */
    function getDonation(uint256 _donationId) external view returns (
        uint256 id,
        address donor,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(_donationId > 0 && _donationId <= donationCount, "Invalid donation ID");
        
        Donation memory donation = donations[_donationId];
        
        return (
            donation.id,
            donation.donor,
            donation.amount,
            donation.timestamp,
            donation.message
        );
    }
    
    /**
     * @dev Returns all donations made by a specific donor
     * @param _donor The address of the donor
     * @return Array of donation IDs
     */
    function getDonationsByDonor(address _donor) external view returns (uint256[] memory) {
        return donorDonationIds[_donor];
    }
    
    /**
     * @dev Returns the total amount donated by a specific donor
     * @param _donor The address of the donor
     * @return The total amount donated
     */
    function getDonorTotalAmount(address _donor) external view returns (uint256) {
        return donorTotalAmount[_donor];
    }
    
    /**
     * @dev Returns the caller's total donation amount
     * @return The total amount donated by the caller
     */
    function getMyTotalDonations() external view returns (uint256) {
        return donorTotalAmount[msg.sender];
    }
    
    /**
     * @dev Returns the caller's donation IDs
     * @return Array of donation IDs
     */
    function getMyDonations() external view returns (uint256[] memory) {
        return donorDonationIds[msg.sender];
    }
    
    /**
     * @dev Returns all donations (use with caution for large datasets)
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
     * @dev Returns the latest N donations
     * @param _count The number of recent donations to retrieve
     * @return Array of recent donations
     */
    function getRecentDonations(uint256 _count) external view returns (Donation[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > donationCount ? donationCount : _count;
        Donation[] memory recentDonations = new Donation[](count);
        
        uint256 startIndex = donationCount - count + 1;
        
        for (uint256 i = 0; i < count; i++) {
            recentDonations[i] = donations[startIndex + i];
        }
        
        return recentDonations;
    }
    
    /**
     * @dev Returns the top donors by amount
     * @param _limit The maximum number of top donors to return
     * @return donors Array of donor addresses
     * @return amounts Array of corresponding donation amounts
     */
    function getTopDonors(uint256 _limit) external view returns (address[] memory donors, uint256[] memory amounts) {
        require(_limit > 0, "Limit must be greater than 0");
        
        // Get unique donors
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
        
        // Determine actual limit
        uint256 actualLimit = _limit > uniqueCount ? uniqueCount : _limit;
        
        donors = new address[](actualLimit);
        amounts = new uint256[](actualLimit);
        
        // Simple selection sort for top donors
        for (uint256 i = 0; i < actualLimit; i++) {
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
            
            if (maxDonor != address(0)) {
                donors[i] = maxDonor;
                amounts[i] = maxAmount;
                uniqueDonors[maxIndex] = address(0);
            }
        }
        
        return (donors, amounts);
    }
    
    /**
     * @dev Returns the current contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the total number of donations
     * @return The donation count
     */
    function getTotalDonationCount() external view returns (uint256) {
        return donationCount;
    }
    
    /**
     * @dev Transfers ownership of the charity to a new owner
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != charityOwner, "New owner must be different");
        
        charityOwner = _newOwner;
    }
}
