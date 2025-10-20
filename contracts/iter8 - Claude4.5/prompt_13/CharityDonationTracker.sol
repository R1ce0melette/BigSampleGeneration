// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CharityDonationTracker
 * @dev Contract for tracking charity donations with full transparency
 */
contract CharityDonationTracker {
    // Donation structure
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
        string message;
        uint256 id;
    }

    // Donor statistics
    struct DonorStats {
        uint256 totalDonated;
        uint256 donationCount;
        uint256 firstDonationTime;
        uint256 lastDonationTime;
    }

    // State variables
    address public owner;
    address public charityAddress;
    string public charityName;
    string public charityDescription;
    
    uint256 private donationCounter;
    uint256 public totalDonationsReceived;
    uint256 public totalDonorsCount;
    
    mapping(uint256 => Donation) private donations;
    mapping(address => uint256[]) private donorDonationIds;
    mapping(address => DonorStats) private donorStats;
    mapping(address => bool) private isDonor;
    
    uint256[] private allDonationIds;
    address[] private allDonors;

    // Events
    event DonationReceived(address indexed donor, uint256 amount, uint256 indexed donationId, uint256 timestamp);
    event FundsWithdrawn(address indexed charity, uint256 amount, uint256 timestamp);
    event CharityAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event CharityInfoUpdated(string name, string description);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyCharity() {
        require(msg.sender == charityAddress, "Not the charity");
        _;
    }

    constructor(
        address _charityAddress,
        string memory _charityName,
        string memory _charityDescription
    ) {
        require(_charityAddress != address(0), "Invalid charity address");
        
        owner = msg.sender;
        charityAddress = _charityAddress;
        charityName = _charityName;
        charityDescription = _charityDescription;
        donationCounter = 0;
        totalDonationsReceived = 0;
        totalDonorsCount = 0;
    }

    /**
     * @dev Donate to charity with message
     * @param message Optional message with donation
     */
    function donate(string memory message) public payable {
        require(msg.value > 0, "Donation must be greater than 0");

        donationCounter++;
        uint256 donationId = donationCounter;

        Donation memory newDonation = Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message,
            id: donationId
        });

        donations[donationId] = newDonation;
        donorDonationIds[msg.sender].push(donationId);
        allDonationIds.push(donationId);

        // Update donor stats
        if (!isDonor[msg.sender]) {
            isDonor[msg.sender] = true;
            allDonors.push(msg.sender);
            totalDonorsCount++;
            donorStats[msg.sender].firstDonationTime = block.timestamp;
        }

        DonorStats storage stats = donorStats[msg.sender];
        stats.totalDonated += msg.value;
        stats.donationCount++;
        stats.lastDonationTime = block.timestamp;

        totalDonationsReceived += msg.value;

        emit DonationReceived(msg.sender, msg.value, donationId, block.timestamp);
    }

    /**
     * @dev Donate to charity without message
     */
    function donate() public payable {
        donate("");
    }

    /**
     * @dev Withdraw funds to charity address
     * @param amount Amount to withdraw
     */
    function withdrawToCharity(uint256 amount) public onlyCharity {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        payable(charityAddress).transfer(amount);

        emit FundsWithdrawn(charityAddress, amount, block.timestamp);
    }

    /**
     * @dev Withdraw all funds to charity address
     */
    function withdrawAllToCharity() public onlyCharity {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(charityAddress).transfer(balance);

        emit FundsWithdrawn(charityAddress, balance, block.timestamp);
    }

    /**
     * @dev Get donation by ID
     * @param donationId Donation ID
     * @return Donation details
     */
    function getDonation(uint256 donationId) public view returns (Donation memory) {
        require(donationId > 0 && donationId <= donationCounter, "Invalid donation ID");
        return donations[donationId];
    }

    /**
     * @dev Get all donations
     * @return Array of all donations
     */
    function getAllDonations() public view returns (Donation[] memory) {
        Donation[] memory allDonations = new Donation[](allDonationIds.length);
        
        for (uint256 i = 0; i < allDonationIds.length; i++) {
            allDonations[i] = donations[allDonationIds[i]];
        }
        
        return allDonations;
    }

    /**
     * @dev Get recent donations
     * @param count Number of recent donations to retrieve
     * @return Array of recent donations
     */
    function getRecentDonations(uint256 count) public view returns (Donation[] memory) {
        uint256 totalCount = allDonationIds.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        Donation[] memory result = new Donation[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = donations[allDonationIds[totalCount - 1 - i]];
        }

        return result;
    }

    /**
     * @dev Get donations by donor
     * @param donor Donor address
     * @return Array of donations by the donor
     */
    function getDonationsByDonor(address donor) public view returns (Donation[] memory) {
        uint256[] memory ids = donorDonationIds[donor];
        Donation[] memory donorDonations = new Donation[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            donorDonations[i] = donations[ids[i]];
        }

        return donorDonations;
    }

    /**
     * @dev Get donor donation IDs
     * @param donor Donor address
     * @return Array of donation IDs
     */
    function getDonorDonationIds(address donor) public view returns (uint256[] memory) {
        return donorDonationIds[donor];
    }

    /**
     * @dev Get donor statistics
     * @param donor Donor address
     * @return DonorStats structure
     */
    function getDonorStats(address donor) public view returns (DonorStats memory) {
        return donorStats[donor];
    }

    /**
     * @dev Get all donors
     * @return Array of all donor addresses
     */
    function getAllDonors() public view returns (address[] memory) {
        return allDonors;
    }

    /**
     * @dev Get top donors
     * @param count Number of top donors to retrieve
     * @return Array of top donor addresses
     * @return Array of their total donation amounts
     */
    function getTopDonors(uint256 count) 
        public 
        view 
        returns (address[] memory, uint256[] memory) 
    {
        uint256 resultCount = count > allDonors.length ? allDonors.length : count;
        
        address[] memory topDonorAddresses = new address[](resultCount);
        uint256[] memory topDonorAmounts = new uint256[](resultCount);

        // Create a copy of donors for sorting
        address[] memory sortedDonors = new address[](allDonors.length);
        for (uint256 i = 0; i < allDonors.length; i++) {
            sortedDonors[i] = allDonors[i];
        }

        // Simple bubble sort for top donors
        for (uint256 i = 0; i < resultCount && i < sortedDonors.length; i++) {
            for (uint256 j = i + 1; j < sortedDonors.length; j++) {
                if (donorStats[sortedDonors[j]].totalDonated > donorStats[sortedDonors[i]].totalDonated) {
                    address temp = sortedDonors[i];
                    sortedDonors[i] = sortedDonors[j];
                    sortedDonors[j] = temp;
                }
            }
        }

        for (uint256 i = 0; i < resultCount; i++) {
            topDonorAddresses[i] = sortedDonors[i];
            topDonorAmounts[i] = donorStats[sortedDonors[i]].totalDonated;
        }

        return (topDonorAddresses, topDonorAmounts);
    }

    /**
     * @dev Get donations in time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of donations in the time range
     */
    function getDonationsInTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Donation[] memory) 
    {
        require(endTime >= startTime, "Invalid time range");

        uint256 count = 0;
        for (uint256 i = 0; i < allDonationIds.length; i++) {
            Donation memory donation = donations[allDonationIds[i]];
            if (donation.timestamp >= startTime && donation.timestamp <= endTime) {
                count++;
            }
        }

        Donation[] memory result = new Donation[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allDonationIds.length; i++) {
            Donation memory donation = donations[allDonationIds[i]];
            if (donation.timestamp >= startTime && donation.timestamp <= endTime) {
                result[index] = donation;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get donations above amount
     * @param minAmount Minimum donation amount
     * @return Array of donations above the amount
     */
    function getDonationsAboveAmount(uint256 minAmount) 
        public 
        view 
        returns (Donation[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allDonationIds.length; i++) {
            if (donations[allDonationIds[i]].amount >= minAmount) {
                count++;
            }
        }

        Donation[] memory result = new Donation[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allDonationIds.length; i++) {
            Donation memory donation = donations[allDonationIds[i]];
            if (donation.amount >= minAmount) {
                result[index] = donation;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total donation count
     * @return Total number of donations
     */
    function getTotalDonationCount() public view returns (uint256) {
        return donationCounter;
    }

    /**
     * @dev Get total amount received
     * @return Total donations received
     */
    function getTotalAmountReceived() public view returns (uint256) {
        return totalDonationsReceived;
    }

    /**
     * @dev Get current balance
     * @return Current contract balance
     */
    function getCurrentBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get total donors
     * @return Total number of unique donors
     */
    function getTotalDonors() public view returns (uint256) {
        return totalDonorsCount;
    }

    /**
     * @dev Get average donation amount
     * @return Average donation amount
     */
    function getAverageDonation() public view returns (uint256) {
        if (donationCounter == 0) {
            return 0;
        }
        return totalDonationsReceived / donationCounter;
    }

    /**
     * @dev Get largest donation
     * @return Largest donation amount
     * @return Donor address
     * @return Donation ID
     */
    function getLargestDonation() 
        public 
        view 
        returns (uint256 amount, address donor, uint256 donationId) 
    {
        uint256 maxAmount = 0;
        address maxDonor = address(0);
        uint256 maxId = 0;

        for (uint256 i = 0; i < allDonationIds.length; i++) {
            Donation memory donation = donations[allDonationIds[i]];
            if (donation.amount > maxAmount) {
                maxAmount = donation.amount;
                maxDonor = donation.donor;
                maxId = donation.id;
            }
        }

        return (maxAmount, maxDonor, maxId);
    }

    /**
     * @dev Check if address is a donor
     * @param addr Address to check
     * @return true if address has donated
     */
    function isAddressDonor(address addr) public view returns (bool) {
        return isDonor[addr];
    }

    /**
     * @dev Get charity summary
     * @return name Charity name
     * @return description Charity description
     * @return charityAddr Charity address
     * @return totalReceived Total donations received
     * @return currentBalance Current contract balance
     * @return donorCount Total number of donors
     * @return donationCount Total number of donations
     */
    function getCharitySummary() 
        public 
        view 
        returns (
            string memory name,
            string memory description,
            address charityAddr,
            uint256 totalReceived,
            uint256 currentBalance,
            uint256 donorCount,
            uint256 donationCount
        ) 
    {
        return (
            charityName,
            charityDescription,
            charityAddress,
            totalDonationsReceived,
            address(this).balance,
            totalDonorsCount,
            donationCounter
        );
    }

    /**
     * @dev Update charity address
     * @param newCharityAddress New charity address
     */
    function updateCharityAddress(address newCharityAddress) public onlyOwner {
        require(newCharityAddress != address(0), "Invalid charity address");
        require(newCharityAddress != charityAddress, "Same as current address");

        address oldAddress = charityAddress;
        charityAddress = newCharityAddress;

        emit CharityAddressUpdated(oldAddress, newCharityAddress);
    }

    /**
     * @dev Update charity information
     * @param newName New charity name
     * @param newDescription New charity description
     */
    function updateCharityInfo(string memory newName, string memory newDescription) public onlyOwner {
        charityName = newName;
        charityDescription = newDescription;

        emit CharityInfoUpdated(newName, newDescription);
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }

    /**
     * @dev Receive function to accept direct ETH transfers
     */
    receive() external payable {
        donate("");
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        donate("");
    }
}
