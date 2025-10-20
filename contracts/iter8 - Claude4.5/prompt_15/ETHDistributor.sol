// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ETHDistributor
 * @dev Contract that allows the owner to distribute ETH evenly among a list of recipients
 */
contract ETHDistributor {
    // Distribution record
    struct Distribution {
        address[] recipients;
        uint256 amountPerRecipient;
        uint256 totalAmount;
        uint256 timestamp;
        uint256 id;
    }

    // Recipient tracking
    struct RecipientStats {
        uint256 totalReceived;
        uint256 distributionCount;
        uint256 lastReceivedTime;
    }

    // State variables
    address public owner;
    uint256 private distributionCounter;
    
    mapping(uint256 => Distribution) private distributions;
    mapping(address => uint256[]) private recipientDistributionIds;
    mapping(address => RecipientStats) private recipientStats;
    mapping(address => bool) private hasReceivedDistribution;
    
    uint256[] private allDistributionIds;
    address[] private allRecipients;
    
    uint256 public totalDistributed;
    uint256 public totalDistributionCount;

    // Events
    event ETHDistributed(uint256 indexed distributionId, uint256 recipientCount, uint256 amountPerRecipient, uint256 totalAmount, uint256 timestamp);
    event RecipientPaid(address indexed recipient, uint256 amount, uint256 indexed distributionId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        distributionCounter = 0;
        totalDistributed = 0;
        totalDistributionCount = 0;
    }

    /**
     * @dev Distribute ETH evenly among recipients
     * @param recipients Array of recipient addresses
     */
    function distribute(address[] memory recipients) public onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(address(this).balance > 0, "Insufficient contract balance");

        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
        }

        uint256 amountPerRecipient = address(this).balance / recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient would be 0");

        distributionCounter++;
        uint256 distributionId = distributionCounter;

        // Create distribution record
        Distribution storage newDistribution = distributions[distributionId];
        newDistribution.recipients = recipients;
        newDistribution.amountPerRecipient = amountPerRecipient;
        newDistribution.totalAmount = amountPerRecipient * recipients.length;
        newDistribution.timestamp = block.timestamp;
        newDistribution.id = distributionId;

        allDistributionIds.push(distributionId);

        // Distribute to each recipient
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            
            payable(recipient).transfer(amountPerRecipient);

            // Update recipient tracking
            recipientDistributionIds[recipient].push(distributionId);
            
            if (!hasReceivedDistribution[recipient]) {
                hasReceivedDistribution[recipient] = true;
                allRecipients.push(recipient);
            }

            RecipientStats storage stats = recipientStats[recipient];
            stats.totalReceived += amountPerRecipient;
            stats.distributionCount++;
            stats.lastReceivedTime = block.timestamp;

            emit RecipientPaid(recipient, amountPerRecipient, distributionId);
        }

        totalDistributed += newDistribution.totalAmount;
        totalDistributionCount++;

        emit ETHDistributed(
            distributionId,
            recipients.length,
            amountPerRecipient,
            newDistribution.totalAmount,
            block.timestamp
        );
    }

    /**
     * @dev Distribute specific amount evenly among recipients
     * @param recipients Array of recipient addresses
     * @param totalAmount Total amount to distribute
     */
    function distributeAmount(address[] memory recipients, uint256 totalAmount) public onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(totalAmount > 0, "Amount must be greater than 0");
        require(address(this).balance >= totalAmount, "Insufficient contract balance");

        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
        }

        uint256 amountPerRecipient = totalAmount / recipients.length;
        require(amountPerRecipient > 0, "Amount per recipient would be 0");

        distributionCounter++;
        uint256 distributionId = distributionCounter;

        // Create distribution record
        Distribution storage newDistribution = distributions[distributionId];
        newDistribution.recipients = recipients;
        newDistribution.amountPerRecipient = amountPerRecipient;
        newDistribution.totalAmount = amountPerRecipient * recipients.length;
        newDistribution.timestamp = block.timestamp;
        newDistribution.id = distributionId;

        allDistributionIds.push(distributionId);

        // Distribute to each recipient
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            
            payable(recipient).transfer(amountPerRecipient);

            // Update recipient tracking
            recipientDistributionIds[recipient].push(distributionId);
            
            if (!hasReceivedDistribution[recipient]) {
                hasReceivedDistribution[recipient] = true;
                allRecipients.push(recipient);
            }

            RecipientStats storage stats = recipientStats[recipient];
            stats.totalReceived += amountPerRecipient;
            stats.distributionCount++;
            stats.lastReceivedTime = block.timestamp;

            emit RecipientPaid(recipient, amountPerRecipient, distributionId);
        }

        totalDistributed += newDistribution.totalAmount;
        totalDistributionCount++;

        emit ETHDistributed(
            distributionId,
            recipients.length,
            amountPerRecipient,
            newDistribution.totalAmount,
            block.timestamp
        );
    }

    /**
     * @dev Get distribution by ID
     * @param distributionId Distribution ID
     * @return Distribution details
     */
    function getDistribution(uint256 distributionId) public view returns (Distribution memory) {
        require(distributionId > 0 && distributionId <= distributionCounter, "Invalid distribution ID");
        return distributions[distributionId];
    }

    /**
     * @dev Get all distributions
     * @return Array of all distributions
     */
    function getAllDistributions() public view returns (Distribution[] memory) {
        Distribution[] memory allDistributions = new Distribution[](allDistributionIds.length);
        
        for (uint256 i = 0; i < allDistributionIds.length; i++) {
            allDistributions[i] = distributions[allDistributionIds[i]];
        }
        
        return allDistributions;
    }

    /**
     * @dev Get recent distributions
     * @param count Number of recent distributions to retrieve
     * @return Array of recent distributions
     */
    function getRecentDistributions(uint256 count) public view returns (Distribution[] memory) {
        uint256 totalCount = allDistributionIds.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        Distribution[] memory result = new Distribution[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = distributions[allDistributionIds[totalCount - 1 - i]];
        }

        return result;
    }

    /**
     * @dev Get distributions for a recipient
     * @param recipient Recipient address
     * @return Array of distribution IDs
     */
    function getRecipientDistributionIds(address recipient) public view returns (uint256[] memory) {
        return recipientDistributionIds[recipient];
    }

    /**
     * @dev Get distributions involving a recipient
     * @param recipient Recipient address
     * @return Array of distributions
     */
    function getRecipientDistributions(address recipient) public view returns (Distribution[] memory) {
        uint256[] memory ids = recipientDistributionIds[recipient];
        Distribution[] memory recipientDistributions = new Distribution[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            recipientDistributions[i] = distributions[ids[i]];
        }

        return recipientDistributions;
    }

    /**
     * @dev Get recipient statistics
     * @param recipient Recipient address
     * @return RecipientStats structure
     */
    function getRecipientStats(address recipient) public view returns (RecipientStats memory) {
        return recipientStats[recipient];
    }

    /**
     * @dev Get all recipients
     * @return Array of all recipient addresses
     */
    function getAllRecipients() public view returns (address[] memory) {
        return allRecipients;
    }

    /**
     * @dev Get top recipients by amount received
     * @param count Number of top recipients to retrieve
     * @return Array of recipient addresses
     * @return Array of amounts received
     */
    function getTopRecipients(uint256 count) 
        public 
        view 
        returns (address[] memory, uint256[] memory) 
    {
        uint256 resultCount = count > allRecipients.length ? allRecipients.length : count;
        
        address[] memory topRecipientAddresses = new address[](resultCount);
        uint256[] memory topRecipientAmounts = new uint256[](resultCount);

        // Create a copy of recipients for sorting
        address[] memory sortedRecipients = new address[](allRecipients.length);
        for (uint256 i = 0; i < allRecipients.length; i++) {
            sortedRecipients[i] = allRecipients[i];
        }

        // Simple bubble sort for top recipients
        for (uint256 i = 0; i < resultCount && i < sortedRecipients.length; i++) {
            for (uint256 j = i + 1; j < sortedRecipients.length; j++) {
                if (recipientStats[sortedRecipients[j]].totalReceived > recipientStats[sortedRecipients[i]].totalReceived) {
                    address temp = sortedRecipients[i];
                    sortedRecipients[i] = sortedRecipients[j];
                    sortedRecipients[j] = temp;
                }
            }
        }

        for (uint256 i = 0; i < resultCount; i++) {
            topRecipientAddresses[i] = sortedRecipients[i];
            topRecipientAmounts[i] = recipientStats[sortedRecipients[i]].totalReceived;
        }

        return (topRecipientAddresses, topRecipientAmounts);
    }

    /**
     * @dev Calculate distribution amount per recipient
     * @param recipients Array of recipient addresses
     * @return Amount each recipient would receive
     */
    function calculateDistributionAmount(address[] memory recipients) public view returns (uint256) {
        require(recipients.length > 0, "No recipients provided");
        return address(this).balance / recipients.length;
    }

    /**
     * @dev Calculate distribution amount for specific total
     * @param recipients Array of recipient addresses
     * @param totalAmount Total amount to distribute
     * @return Amount each recipient would receive
     */
    function calculateDistributionAmountForTotal(address[] memory recipients, uint256 totalAmount) 
        public 
        pure 
        returns (uint256) 
    {
        require(recipients.length > 0, "No recipients provided");
        require(totalAmount > 0, "Total amount must be greater than 0");
        return totalAmount / recipients.length;
    }

    /**
     * @dev Get contract balance
     * @return Current contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get total distributed amount
     * @return Total amount distributed
     */
    function getTotalDistributed() public view returns (uint256) {
        return totalDistributed;
    }

    /**
     * @dev Get total distribution count
     * @return Total number of distributions
     */
    function getTotalDistributionCount() public view returns (uint256) {
        return totalDistributionCount;
    }

    /**
     * @dev Get total unique recipients
     * @return Total number of unique recipients
     */
    function getTotalRecipients() public view returns (uint256) {
        return allRecipients.length;
    }

    /**
     * @dev Check if address has received distribution
     * @param recipient Recipient address
     * @return true if recipient has received distribution
     */
    function hasReceivedDistributionBefore(address recipient) public view returns (bool) {
        return hasReceivedDistribution[recipient];
    }

    /**
     * @dev Deposit ETH to contract
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw ETH from contract (only owner)
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        payable(owner).transfer(amount);

        emit FundsWithdrawn(owner, amount);
    }

    /**
     * @dev Withdraw all ETH from contract (only owner)
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);

        emit FundsWithdrawn(owner, balance);
    }

    /**
     * @dev Get distributor summary
     * @return totalDistributions Total number of distributions
     * @return totalAmountDistributed Total amount distributed
     * @return uniqueRecipients Number of unique recipients
     * @return currentBalance Current contract balance
     */
    function getDistributorSummary() 
        public 
        view 
        returns (
            uint256 totalDistributions,
            uint256 totalAmountDistributed,
            uint256 uniqueRecipients,
            uint256 currentBalance
        ) 
    {
        return (
            totalDistributionCount,
            totalDistributed,
            allRecipients.length,
            address(this).balance
        );
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
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
