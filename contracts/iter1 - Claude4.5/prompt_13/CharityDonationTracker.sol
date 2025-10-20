// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CharityDonationTracker
 * @dev A contract for tracking charity donations where all donations and total amounts are visible on-chain
 */
contract CharityDonationTracker {
    address public owner;
    string public charityName;
    string public charityDescription;
    
    struct Donation {
        uint256 id;
        address donor;
        uint256 amount;
        uint256 timestamp;
        string message;
    }
    
    Donation[] public donations;
    mapping(address => uint256[]) private donorDonationIds;
    mapping(address => uint256) public totalDonatedByDonor;
    
    address[] private donors;
    mapping(address => bool) private isDonor;
    
    uint256 public totalDonations;
    uint256 public donationCount;
    
    event DonationReceived(
        uint256 indexed donationId,
        address indexed donor,
        uint256 amount,
        string message,
        uint256 timestamp
    );
    
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event CharityInfoUpdated(string name, string description);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the charity
     * @param _charityName Name of the charity
     * @param _charityDescription Description of the charity
     */
    constructor(string memory _charityName, string memory _charityDescription) {
        owner = msg.sender;
        charityName = _charityName;
        charityDescription = _charityDescription;
    }
    
    /**
     * @dev Make a donation to the charity
     * @param message Optional message from the donor
     */
    function donate(string memory message) external payable {
        require(msg.value > 0, "Donation must be greater than 0");
        
        uint256 donationId = donations.length;
        
        Donation memory newDonation = Donation({
            id: donationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message
        });
        
        donations.push(newDonation);
        donorDonationIds[msg.sender].push(donationId);
        totalDonatedByDonor[msg.sender] += msg.value;
        
        if (!isDonor[msg.sender]) {
            donors.push(msg.sender);
            isDonor[msg.sender] = true;
        }
        
        totalDonations += msg.value;
        donationCount++;
        
        emit DonationReceived(donationId, msg.sender, msg.value, message, block.timestamp);
    }
    
    /**
     * @dev Withdraw funds from the charity (only owner)
     * @param amount The amount to withdraw
     * @param recipient The address to send funds to
     */
    function withdraw(uint256 amount, address payable recipient) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(recipient != address(0), "Invalid recipient address");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(recipient, amount);
    }
    
    /**
     * @dev Withdraw all funds (only owner)
     * @param recipient The address to send funds to
     */
    function withdrawAll(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(recipient, balance);
    }
    
    /**
     * @dev Update charity information (only owner)
     * @param _charityName New charity name
     * @param _charityDescription New charity description
     */
    function updateCharityInfo(string memory _charityName, string memory _charityDescription) external onlyOwner {
        require(bytes(_charityName).length > 0, "Name cannot be empty");
        
        charityName = _charityName;
        charityDescription = _charityDescription;
        
        emit CharityInfoUpdated(_charityName, _charityDescription);
    }
    
    /**
     * @dev Get a specific donation by ID
     * @param donationId The ID of the donation
     * @return id Donation ID
     * @return donor Address of the donor
     * @return amount Donation amount
     * @return timestamp When the donation was made
     * @return message Donation message
     */
    function getDonation(uint256 donationId) external view returns (
        uint256 id,
        address donor,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(donationId < donations.length, "Donation does not exist");
        
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
     * @dev Get all donations
     * @return Array of all donations
     */
    function getAllDonations() external view returns (Donation[] memory) {
        return donations;
    }
    
    /**
     * @dev Get donation IDs for a specific donor
     * @param donor The address of the donor
     * @return Array of donation IDs
     */
    function getDonorDonationIds(address donor) external view returns (uint256[] memory) {
        return donorDonationIds[donor];
    }
    
    /**
     * @dev Get all donations made by a specific donor
     * @param donor The address of the donor
     * @return Array of donations
     */
    function getDonationsByDonor(address donor) external view returns (Donation[] memory) {
        uint256[] memory donationIds = donorDonationIds[donor];
        Donation[] memory donorDonations = new Donation[](donationIds.length);
        
        for (uint256 i = 0; i < donationIds.length; i++) {
            donorDonations[i] = donations[donationIds[i]];
        }
        
        return donorDonations;
    }
    
    /**
     * @dev Get all donors
     * @return Array of donor addresses
     */
    function getAllDonors() external view returns (address[] memory) {
        return donors;
    }
    
    /**
     * @dev Get the latest N donations
     * @param count Number of donations to retrieve
     * @return Array of the latest donations
     */
    function getLatestDonations(uint256 count) external view returns (Donation[] memory) {
        if (count > donations.length) {
            count = donations.length;
        }
        
        Donation[] memory latestDonations = new Donation[](count);
        uint256 startIndex = donations.length - count;
        
        for (uint256 i = 0; i < count; i++) {
            latestDonations[i] = donations[startIndex + i];
        }
        
        return latestDonations;
    }
    
    /**
     * @dev Get top N donors by total donated amount
     * @param count Number of top donors to retrieve
     * @return topDonors Array of donor addresses
     * @return amounts Array of corresponding donation amounts
     */
    function getTopDonors(uint256 count) external view returns (
        address[] memory topDonors,
        uint256[] memory amounts
    ) {
        if (count > donors.length) {
            count = donors.length;
        }
        
        // Create temporary arrays
        address[] memory tempDonors = new address[](donors.length);
        uint256[] memory tempAmounts = new uint256[](donors.length);
        
        // Copy data
        for (uint256 i = 0; i < donors.length; i++) {
            tempDonors[i] = donors[i];
            tempAmounts[i] = totalDonatedByDonor[donors[i]];
        }
        
        // Simple bubble sort (descending)
        for (uint256 i = 0; i < donors.length; i++) {
            for (uint256 j = i + 1; j < donors.length; j++) {
                if (tempAmounts[j] > tempAmounts[i]) {
                    // Swap amounts
                    uint256 tempAmount = tempAmounts[i];
                    tempAmounts[i] = tempAmounts[j];
                    tempAmounts[j] = tempAmount;
                    
                    // Swap addresses
                    address tempDonor = tempDonors[i];
                    tempDonors[i] = tempDonors[j];
                    tempDonors[j] = tempDonor;
                }
            }
        }
        
        // Return top count
        topDonors = new address[](count);
        amounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            topDonors[i] = tempDonors[i];
            amounts[i] = tempAmounts[i];
        }
        
        return (topDonors, amounts);
    }
    
    /**
     * @dev Get donations within a time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of donations within the time range
     */
    function getDonationsByTimeRange(uint256 startTime, uint256 endTime) external view returns (Donation[] memory) {
        require(startTime <= endTime, "Invalid time range");
        
        // Count matching donations
        uint256 count = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].timestamp >= startTime && donations[i].timestamp <= endTime) {
                count++;
            }
        }
        
        // Create array and populate
        Donation[] memory filteredDonations = new Donation[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].timestamp >= startTime && donations[i].timestamp <= endTime) {
                filteredDonations[index] = donations[i];
                index++;
            }
        }
        
        return filteredDonations;
    }
    
    /**
     * @dev Get charity statistics
     * @return _totalDonations Total amount donated
     * @return _donationCount Number of donations
     * @return _donorCount Number of unique donors
     * @return _currentBalance Current contract balance
     */
    function getCharityStats() external view returns (
        uint256 _totalDonations,
        uint256 _donationCount,
        uint256 _donorCount,
        uint256 _currentBalance
    ) {
        return (
            totalDonations,
            donationCount,
            donors.length,
            address(this).balance
        );
    }
    
    /**
     * @dev Get the current balance of the charity
     * @return The contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    /**
     * @dev Fallback function to receive donations
     */
    receive() external payable {
        require(msg.value > 0, "Donation must be greater than 0");
        
        uint256 donationId = donations.length;
        
        Donation memory newDonation = Donation({
            id: donationId,
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        });
        
        donations.push(newDonation);
        donorDonationIds[msg.sender].push(donationId);
        totalDonatedByDonor[msg.sender] += msg.value;
        
        if (!isDonor[msg.sender]) {
            donors.push(msg.sender);
            isDonor[msg.sender] = true;
        }
        
        totalDonations += msg.value;
        donationCount++;
        
        emit DonationReceived(donationId, msg.sender, msg.value, "", block.timestamp);
    }
}
