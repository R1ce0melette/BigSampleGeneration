// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TipJar
 * @dev A contract for a tip jar where users can send ETH to a creator and the contract keeps track of total tips received
 */
contract TipJar {
    address payable public creator;
    
    struct Tip {
        address tipper;
        uint256 amount;
        uint256 timestamp;
        string message;
    }
    
    Tip[] public tips;
    mapping(address => uint256) public totalTippedByUser;
    mapping(address => uint256[]) private userTipIds;
    
    uint256 public totalTipsReceived;
    uint256 public totalTipsCount;
    
    address[] private tippers;
    mapping(address => bool) private hasTipped;
    
    event TipReceived(
        address indexed tipper,
        uint256 amount,
        string message,
        uint256 timestamp
    );
    
    event TipsWithdrawn(address indexed creator, uint256 amount);
    
    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call this function");
        _;
    }
    
    /**
     * @dev Constructor to set the creator
     */
    constructor() {
        creator = payable(msg.sender);
    }
    
    /**
     * @dev Send a tip with a message
     * @param message Optional message with the tip
     */
    function sendTip(string memory message) external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        uint256 tipId = tips.length;
        
        Tip memory newTip = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message
        });
        
        tips.push(newTip);
        userTipIds[msg.sender].push(tipId);
        totalTippedByUser[msg.sender] += msg.value;
        
        if (!hasTipped[msg.sender]) {
            tippers.push(msg.sender);
            hasTipped[msg.sender] = true;
        }
        
        totalTipsReceived += msg.value;
        totalTipsCount++;
        
        emit TipReceived(msg.sender, msg.value, message, block.timestamp);
    }
    
    /**
     * @dev Withdraw all tips to creator
     */
    function withdrawTips() external onlyCreator {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        (bool success, ) = creator.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, balance);
    }
    
    /**
     * @dev Withdraw specific amount to creator
     * @param amount The amount to withdraw
     */
    function withdrawAmount(uint256 amount) external onlyCreator {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = creator.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, amount);
    }
    
    /**
     * @dev Get a specific tip by ID
     * @param tipId The ID of the tip
     * @return tipper Address of the tipper
     * @return amount Tip amount
     * @return timestamp When the tip was sent
     * @return message Tip message
     */
    function getTip(uint256 tipId) external view returns (
        address tipper,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(tipId < tips.length, "Tip does not exist");
        
        Tip memory tip = tips[tipId];
        
        return (
            tip.tipper,
            tip.amount,
            tip.timestamp,
            tip.message
        );
    }
    
    /**
     * @dev Get all tips
     * @return Array of all tips
     */
    function getAllTips() external view returns (Tip[] memory) {
        return tips;
    }
    
    /**
     * @dev Get tip IDs sent by a specific user
     * @param tipper The address of the tipper
     * @return Array of tip IDs
     */
    function getTipIdsByUser(address tipper) external view returns (uint256[] memory) {
        return userTipIds[tipper];
    }
    
    /**
     * @dev Get all tips sent by a specific user
     * @param tipper The address of the tipper
     * @return Array of tips
     */
    function getTipsByUser(address tipper) external view returns (Tip[] memory) {
        uint256[] memory tipIds = userTipIds[tipper];
        Tip[] memory userTips = new Tip[](tipIds.length);
        
        for (uint256 i = 0; i < tipIds.length; i++) {
            userTips[i] = tips[tipIds[i]];
        }
        
        return userTips;
    }
    
    /**
     * @dev Get all unique tippers
     * @return Array of tipper addresses
     */
    function getAllTippers() external view returns (address[] memory) {
        return tippers;
    }
    
    /**
     * @dev Get the latest N tips
     * @param count Number of tips to retrieve
     * @return Array of the latest tips
     */
    function getLatestTips(uint256 count) external view returns (Tip[] memory) {
        if (count > tips.length) {
            count = tips.length;
        }
        
        Tip[] memory latestTips = new Tip[](count);
        uint256 startIndex = tips.length - count;
        
        for (uint256 i = 0; i < count; i++) {
            latestTips[i] = tips[startIndex + i];
        }
        
        return latestTips;
    }
    
    /**
     * @dev Get top N tippers by total amount
     * @param count Number of top tippers to retrieve
     * @return topTippers Array of tipper addresses
     * @return amounts Array of corresponding tip amounts
     */
    function getTopTippers(uint256 count) external view returns (
        address[] memory topTippers,
        uint256[] memory amounts
    ) {
        if (count > tippers.length) {
            count = tippers.length;
        }
        
        // Create temporary arrays
        address[] memory tempTippers = new address[](tippers.length);
        uint256[] memory tempAmounts = new uint256[](tippers.length);
        
        // Copy data
        for (uint256 i = 0; i < tippers.length; i++) {
            tempTippers[i] = tippers[i];
            tempAmounts[i] = totalTippedByUser[tippers[i]];
        }
        
        // Simple bubble sort (descending)
        for (uint256 i = 0; i < tippers.length; i++) {
            for (uint256 j = i + 1; j < tippers.length; j++) {
                if (tempAmounts[j] > tempAmounts[i]) {
                    // Swap amounts
                    uint256 tempAmount = tempAmounts[i];
                    tempAmounts[i] = tempAmounts[j];
                    tempAmounts[j] = tempAmount;
                    
                    // Swap addresses
                    address tempTipper = tempTippers[i];
                    tempTippers[i] = tempTippers[j];
                    tempTippers[j] = tempTipper;
                }
            }
        }
        
        // Return top count
        topTippers = new address[](count);
        amounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            topTippers[i] = tempTippers[i];
            amounts[i] = tempAmounts[i];
        }
        
        return (topTippers, amounts);
    }
    
    /**
     * @dev Get tips within a time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of tips within the time range
     */
    function getTipsByTimeRange(uint256 startTime, uint256 endTime) external view returns (Tip[] memory) {
        require(startTime <= endTime, "Invalid time range");
        
        // Count matching tips
        uint256 count = 0;
        for (uint256 i = 0; i < tips.length; i++) {
            if (tips[i].timestamp >= startTime && tips[i].timestamp <= endTime) {
                count++;
            }
        }
        
        // Create array and populate
        Tip[] memory filteredTips = new Tip[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < tips.length; i++) {
            if (tips[i].timestamp >= startTime && tips[i].timestamp <= endTime) {
                filteredTips[index] = tips[i];
                index++;
            }
        }
        
        return filteredTips;
    }
    
    /**
     * @dev Get statistics
     * @return _totalTipsReceived Total ETH received
     * @return _totalTipsCount Number of tips
     * @return _uniqueTippers Number of unique tippers
     * @return _currentBalance Current contract balance
     */
    function getStats() external view returns (
        uint256 _totalTipsReceived,
        uint256 _totalTipsCount,
        uint256 _uniqueTippers,
        uint256 _currentBalance
    ) {
        return (
            totalTipsReceived,
            totalTipsCount,
            tippers.length,
            address(this).balance
        );
    }
    
    /**
     * @dev Get current balance
     * @return The contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get total tips count
     * @return The total number of tips
     */
    function getTotalTipsCount() external view returns (uint256) {
        return tips.length;
    }
    
    /**
     * @dev Get average tip amount
     * @return The average tip (0 if no tips)
     */
    function getAverageTip() external view returns (uint256) {
        if (totalTipsCount == 0) {
            return 0;
        }
        return totalTipsReceived / totalTipsCount;
    }
    
    /**
     * @dev Transfer creator role to a new address
     * @param newCreator The address of the new creator
     */
    function transferCreator(address payable newCreator) external onlyCreator {
        require(newCreator != address(0), "Invalid address");
        creator = newCreator;
    }
    
    /**
     * @dev Receive function to accept tips without message
     */
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        uint256 tipId = tips.length;
        
        Tip memory newTip = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        });
        
        tips.push(newTip);
        userTipIds[msg.sender].push(tipId);
        totalTippedByUser[msg.sender] += msg.value;
        
        if (!hasTipped[msg.sender]) {
            tippers.push(msg.sender);
            hasTipped[msg.sender] = true;
        }
        
        totalTipsReceived += msg.value;
        totalTipsCount++;
        
        emit TipReceived(msg.sender, msg.value, "", block.timestamp);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        uint256 tipId = tips.length;
        
        Tip memory newTip = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        });
        
        tips.push(newTip);
        userTipIds[msg.sender].push(tipId);
        totalTippedByUser[msg.sender] += msg.value;
        
        if (!hasTipped[msg.sender]) {
            tippers.push(msg.sender);
            hasTipped[msg.sender] = true;
        }
        
        totalTipsReceived += msg.value;
        totalTipsCount++;
        
        emit TipReceived(msg.sender, msg.value, "", block.timestamp);
    }
}
