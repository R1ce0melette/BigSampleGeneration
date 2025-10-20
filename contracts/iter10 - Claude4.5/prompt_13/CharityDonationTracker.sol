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

    event DonationReceived(uint256 indexed donationId, address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate(string memory message) external payable {
        require(msg.value > 0, "Donation must be greater than 0");

        donationCount++;
        totalDonations += msg.value;
        donorTotalDonations[msg.sender] += msg.value;

        donations[donationCount] = Donation({
            id: donationCount,
            donor: msg.sender,
            amount: msg.value,
            message: message,
            timestamp: block.timestamp
        });

        donorDonationIds[msg.sender].push(donationCount);

        emit DonationReceived(donationCount, msg.sender, msg.value, message, block.timestamp);
    }

    function getDonation(uint256 donationId) external view returns (
        uint256 id,
        address donor,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(donationId > 0 && donationId <= donationCount, "Donation does not exist");
        Donation memory donation = donations[donationId];
        return (donation.id, donation.donor, donation.amount, donation.message, donation.timestamp);
    }

    function getDonorDonations(address donor) external view returns (uint256[] memory) {
        return donorDonationIds[donor];
    }

    function getDonorTotal(address donor) external view returns (uint256) {
        return donorTotalDonations[donor];
    }

    function getLatestDonations(uint256 count) external view returns (Donation[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > donationCount ? donationCount : count;
        Donation[] memory latestDonations = new Donation[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            latestDonations[i] = donations[donationCount - i];
        }

        return latestDonations;
    }

    function getTopDonors(uint256 count) external view returns (address[] memory, uint256[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        // Get unique donors
        address[] memory uniqueDonors = new address[](donationCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 1; i <= donationCount; i++) {
            address donor = donations[i].donor;
            bool isUnique = true;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueDonors[j] == donor) {
                    isUnique = false;
                    break;
                }
            }
            
            if (isUnique) {
                uniqueDonors[uniqueCount] = donor;
                uniqueCount++;
            }
        }

        uint256 resultCount = count > uniqueCount ? uniqueCount : count;
        address[] memory topDonors = new address[](resultCount);
        uint256[] memory topAmounts = new uint256[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 maxAmount = 0;
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (donorTotalDonations[uniqueDonors[j]] > maxAmount) {
                    bool alreadyAdded = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (topDonors[k] == uniqueDonors[j]) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    if (!alreadyAdded) {
                        maxAmount = donorTotalDonations[uniqueDonors[j]];
                        maxIndex = j;
                    }
                }
            }
            
            topDonors[i] = uniqueDonors[maxIndex];
            topAmounts[i] = maxAmount;
        }

        return (topDonors, topAmounts);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        require(msg.value > 0, "Donation must be greater than 0");

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
}
