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
    
    mapping(address => uint256) public totalTippedByAddress;
    mapping(address => uint256) public tipCountByAddress;
    
    uint256 public totalTipsReceived;
    uint256 public totalTipCount;
    
    // Events
    event TipReceived(address indexed tipper, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed creator, uint256 amount);
    event CreatorChanged(address indexed oldCreator, address indexed newCreator);
    
    constructor() {
        creator = payable(msg.sender);
    }
    
    /**
     * @dev Send a tip to the creator
     * @param message Optional message with the tip
     */
    function sendTip(string memory message) external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message
        }));
        
        totalTippedByAddress[msg.sender] += msg.value;
        tipCountByAddress[msg.sender]++;
        totalTipsReceived += msg.value;
        totalTipCount++;
        
        emit TipReceived(msg.sender, msg.value, message, block.timestamp);
    }
    
    /**
     * @dev Withdraw tips to the creator
     * @param amount Amount to withdraw (0 to withdraw all)
     */
    function withdraw(uint256 amount) external {
        require(msg.sender == creator, "Only creator can withdraw");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        uint256 withdrawAmount = amount == 0 ? balance : amount;
        require(withdrawAmount <= balance, "Insufficient balance");
        
        (bool success, ) = creator.call{value: withdrawAmount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(creator, withdrawAmount);
    }
    
    /**
     * @dev Get a specific tip by index
     * @param index The index of the tip
     * @return tipper The tipper's address
     * @return amount The tip amount
     * @return timestamp The tip timestamp
     * @return message The tip message
     */
    function getTip(uint256 index) external view returns (
        address tipper,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(index < tips.length, "Invalid tip index");
        Tip memory tip = tips[index];
        
        return (
            tip.tipper,
            tip.amount,
            tip.timestamp,
            tip.message
        );
    }
    
    /**
     * @dev Get the total number of tips
     * @return The total tip count
     */
    function getTipCount() external view returns (uint256) {
        return tips.length;
    }
    
    /**
     * @dev Get the latest N tips
     * @param count Number of recent tips to retrieve
     * @return tippers Array of tipper addresses
     * @return amounts Array of tip amounts
     * @return timestamps Array of timestamps
     * @return messages Array of messages
     */
    function getLatestTips(uint256 count) external view returns (
        address[] memory tippers,
        uint256[] memory amounts,
        uint256[] memory timestamps,
        string[] memory messages
    ) {
        if (count > tips.length) {
            count = tips.length;
        }
        
        tippers = new address[](count);
        amounts = new uint256[](count);
        timestamps = new uint256[](count);
        messages = new string[](count);
        
        for (uint256 i = 0; i < count; i++) {
            uint256 index = tips.length - 1 - i;
            tippers[i] = tips[index].tipper;
            amounts[i] = tips[index].amount;
            timestamps[i] = tips[index].timestamp;
            messages[i] = tips[index].message;
        }
        
        return (tippers, amounts, timestamps, messages);
    }
    
    /**
     * @dev Get all tips from a specific tipper
     * @param tipper The tipper's address
     * @return indices Array of tip indices
     */
    function getTipsByTipper(address tipper) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count tips from this tipper
        for (uint256 i = 0; i < tips.length; i++) {
            if (tips[i].tipper == tipper) {
                count++;
            }
        }
        
        // Collect tip indices
        uint256[] memory indices = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tips.length; i++) {
            if (tips[i].tipper == tipper) {
                indices[index] = i;
                index++;
            }
        }
        
        return indices;
    }
    
    /**
     * @dev Get total amount tipped by an address
     * @param tipper The tipper's address
     * @return The total amount tipped
     */
    function getTotalTippedByAddress(address tipper) external view returns (uint256) {
        return totalTippedByAddress[tipper];
    }
    
    /**
     * @dev Get tip count by an address
     * @param tipper The tipper's address
     * @return The number of tips from this address
     */
    function getTipCountByAddress(address tipper) external view returns (uint256) {
        return tipCountByAddress[tipper];
    }
    
    /**
     * @dev Get the caller's tipping statistics
     * @return totalTipped Total amount tipped by caller
     * @return tipCount Number of tips from caller
     */
    function getMyStats() external view returns (uint256 totalTipped, uint256 tipCount) {
        return (totalTippedByAddress[msg.sender], tipCountByAddress[msg.sender]);
    }
    
    /**
     * @dev Get top tippers
     * @param count Number of top tippers to return
     * @return tippers Array of tipper addresses
     * @return amounts Array of total amounts tipped
     */
    function getTopTippers(uint256 count) external view returns (
        address[] memory tippers,
        uint256[] memory amounts
    ) {
        // Get unique tippers
        address[] memory uniqueTippers = new address[](tips.length);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < tips.length; i++) {
            address tipper = tips[i].tipper;
            bool exists = false;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueTippers[j] == tipper) {
                    exists = true;
                    break;
                }
            }
            
            if (!exists) {
                uniqueTippers[uniqueCount] = tipper;
                uniqueCount++;
            }
        }
        
        // Limit count to actual unique tippers
        if (count > uniqueCount) {
            count = uniqueCount;
        }
        
        tippers = new address[](count);
        amounts = new uint256[](count);
        
        // Simple selection sort to find top tippers
        for (uint256 i = 0; i < count; i++) {
            uint256 maxAmount = 0;
            address maxTipper = address(0);
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (totalTippedByAddress[uniqueTippers[j]] > maxAmount) {
                    maxAmount = totalTippedByAddress[uniqueTippers[j]];
                    maxTipper = uniqueTippers[j];
                    maxIndex = j;
                }
            }
            
            tippers[i] = maxTipper;
            amounts[i] = maxAmount;
            
            // Remove this tipper from consideration
            uniqueTippers[maxIndex] = uniqueTippers[uniqueCount - 1];
            uniqueCount--;
        }
        
        return (tippers, amounts);
    }
    
    /**
     * @dev Get the contract balance
     * @return The contract's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get overall statistics
     * @return _totalTipsReceived Total ETH received
     * @return _totalTipCount Total number of tips
     * @return _currentBalance Current contract balance
     * @return _uniqueTippers Approximate number of unique tippers
     */
    function getStats() external view returns (
        uint256 _totalTipsReceived,
        uint256 _totalTipCount,
        uint256 _currentBalance,
        uint256 _uniqueTippers
    ) {
        // Count unique tippers
        address[] memory uniqueTippers = new address[](tips.length);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < tips.length; i++) {
            address tipper = tips[i].tipper;
            bool exists = false;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueTippers[j] == tipper) {
                    exists = true;
                    break;
                }
            }
            
            if (!exists) {
                uniqueTippers[uniqueCount] = tipper;
                uniqueCount++;
            }
        }
        
        return (
            totalTipsReceived,
            totalTipCount,
            address(this).balance,
            uniqueCount
        );
    }
    
    /**
     * @dev Change the creator address
     * @param newCreator The new creator's address
     */
    function changeCreator(address payable newCreator) external {
        require(msg.sender == creator, "Only creator can change creator");
        require(newCreator != address(0), "New creator cannot be zero address");
        
        address oldCreator = creator;
        creator = newCreator;
        
        emit CreatorChanged(oldCreator, newCreator);
    }
    
    /**
     * @dev Receive function to accept tips without message
     */
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        }));
        
        totalTippedByAddress[msg.sender] += msg.value;
        tipCountByAddress[msg.sender]++;
        totalTipsReceived += msg.value;
        totalTipCount++;
        
        emit TipReceived(msg.sender, msg.value, "", block.timestamp);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        }));
        
        totalTippedByAddress[msg.sender] += msg.value;
        tipCountByAddress[msg.sender]++;
        totalTipsReceived += msg.value;
        totalTipCount++;
        
        emit TipReceived(msg.sender, msg.value, "", block.timestamp);
    }
}
