// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityDonationTracker {
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
    
    // Events
    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Donate to the charity
     * @param _message Optional message with the donation
     */
    function donate(string memory _message) external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        
        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        });
        
        donorDonationIds[msg.sender].push(donationCount);
        
        emit DonationReceived(donationCount, msg.sender, msg.value, _message, block.timestamp);
    }
    
    /**
     * @dev Donate to the charity (fallback for direct transfers)
     */
    receive() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donationCount++;
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;
        
        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            message: "",
            timestamp: block.timestamp
        });
        
        donorDonationIds[msg.sender].push(donationCount);
        
        emit DonationReceived(donationCount, msg.sender, msg.value, "", block.timestamp);
    }
    
    /**
     * @dev Get donation details
     * @param _donationId The ID of the donation
     * @return id The donation ID
     * @return donor The donor address
     * @return amount The donation amount
     * @return message The donation message
     * @return timestamp The timestamp
     */
    function getDonation(uint256 _donationId) external view returns (
        uint256 id,
        address donor,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(_donationId > 0 && _donationId <= donationCount, "Invalid donation ID");
        
        Donation memory donation = donations[_donationId];
        
        return (
            donation.id,
            donation.donor,
            donation.amount,
            donation.message,
            donation.timestamp
        );
    }
    
    /**
     * @dev Get all donation IDs from a specific donor
     * @param _donor The address of the donor
     * @return An array of donation IDs
     */
    function getDonorDonations(address _donor) external view returns (uint256[] memory) {
        return donorDonationIds[_donor];
    }
    
    /**
     * @dev Get total donations from a specific donor
     * @param _donor The address of the donor
     * @return The total amount donated by the donor
     */
    function getDonorTotal(address _donor) external view returns (uint256) {
        return donorTotalDonations[_donor];
    }
    
    /**
     * @dev Get recent donations
     * @param _limit Maximum number of donations to return
     * @return An array of recent donation IDs (most recent first)
     */
    function getRecentDonations(uint256 _limit) external view returns (uint256[] memory) {
        uint256 count = donationCount < _limit ? donationCount : _limit;
        uint256[] memory recentDonationIds = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentDonationIds[i] = donationCount - i;
        }
        
        return recentDonationIds;
    }
    
    /**
     * @dev Get top donors
     * @param _donors Array of donor addresses to check
     * @return topDonors Array of donor addresses sorted by donation amount (descending)
     * @return amounts Array of donation amounts corresponding to each donor
     */
    function getTopDonors(address[] memory _donors) external view returns (
        address[] memory topDonors,
        uint256[] memory amounts
    ) {
        uint256 length = _donors.length;
        topDonors = new address[](length);
        amounts = new uint256[](length);
        
        // Copy donor addresses and amounts
        for (uint256 i = 0; i < length; i++) {
            topDonors[i] = _donors[i];
            amounts[i] = donorTotalDonations[_donors[i]];
        }
        
        // Simple bubble sort (descending)
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (amounts[j] > amounts[i]) {
                    // Swap amounts
                    uint256 tempAmount = amounts[i];
                    amounts[i] = amounts[j];
                    amounts[j] = tempAmount;
                    
                    // Swap addresses
                    address tempAddr = topDonors[i];
                    topDonors[i] = topDonors[j];
                    topDonors[j] = tempAddr;
                }
            }
        }
        
        return (topDonors, amounts);
    }
    
    /**
     * @dev Get charity statistics
     * @return _totalDonations Total amount of donations
     * @return _donationCount Total number of donations
     * @return _balance Current contract balance
     */
    function getStatistics() external view returns (
        uint256 _totalDonations,
        uint256 _donationCount,
        uint256 _balance
    ) {
        return (totalDonations, donationCount, address(this).balance);
    }
    
    /**
     * @dev Withdraw funds to a beneficiary address
     * @param _recipient The address to receive the funds
     * @param _amount The amount to withdraw
     */
    function withdrawFunds(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(_recipient, _amount);
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
