// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TipJar
 * @dev A contract for a tip jar where users can send ETH to a creator and the contract keeps track of total tips received
 */
contract TipJar {
    address payable public creator;
    uint256 public totalTipsReceived;
    uint256 public tipCount;
    
    // Tip structure
    struct Tip {
        uint256 id;
        address tipper;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    // State variables
    mapping(uint256 => Tip) public tips;
    mapping(address => uint256) public tipperTotalAmount;
    mapping(address => uint256[]) public tipperTipIds;
    
    // Leaderboard
    address[] public tippers;
    mapping(address => bool) public hasTipped;
    
    // Events
    event TipReceived(uint256 indexed tipId, address indexed tipper, uint256 amount, string message, uint256 timestamp);
    event TipsWithdrawn(address indexed creator, uint256 amount);
    event CreatorChanged(address indexed oldCreator, address indexed newCreator);
    
    /**
     * @dev Constructor sets the creator
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
        
        tipCount++;
        uint256 tipId = tipCount;
        
        tips[tipId] = Tip({
            id: tipId,
            tipper: msg.sender,
            amount: msg.value,
            message: message,
            timestamp: block.timestamp
        });
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipId);
        
        // Track unique tippers
        if (!hasTipped[msg.sender]) {
            hasTipped[msg.sender] = true;
            tippers.push(msg.sender);
        }
        
        emit TipReceived(tipId, msg.sender, msg.value, message, block.timestamp);
    }
    
    /**
     * @dev Send a tip without a message
     */
    function sendTip() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipCount++;
        uint256 tipId = tipCount;
        
        tips[tipId] = Tip({
            id: tipId,
            tipper: msg.sender,
            amount: msg.value,
            message: "",
            timestamp: block.timestamp
        });
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipId);
        
        // Track unique tippers
        if (!hasTipped[msg.sender]) {
            hasTipped[msg.sender] = true;
            tippers.push(msg.sender);
        }
        
        emit TipReceived(tipId, msg.sender, msg.value, "", block.timestamp);
    }
    
    /**
     * @dev Withdraw tips to creator
     * @param amount The amount to withdraw
     */
    function withdrawTips(uint256 amount) external {
        require(msg.sender == creator, "Only creator can withdraw tips");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = creator.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, amount);
    }
    
    /**
     * @dev Withdraw all tips to creator
     */
    function withdrawAllTips() external {
        require(msg.sender == creator, "Only creator can withdraw tips");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        (bool success, ) = creator.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, balance);
    }
    
    /**
     * @dev Get tip details
     * @param tipId The ID of the tip
     * @return id Tip ID
     * @return tipper Tipper's address
     * @return amount Tip amount
     * @return message Tip message
     * @return timestamp Timestamp
     */
    function getTip(uint256 tipId) external view returns (
        uint256 id,
        address tipper,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(tipId > 0 && tipId <= tipCount, "Invalid tip ID");
        
        Tip memory tip = tips[tipId];
        return (
            tip.id,
            tip.tipper,
            tip.amount,
            tip.message,
            tip.timestamp
        );
    }
    
    /**
     * @dev Get all tips from a specific tipper
     * @param tipper The tipper's address
     * @return Array of tip IDs
     */
    function getTipsByTipper(address tipper) external view returns (uint256[] memory) {
        return tipperTipIds[tipper];
    }
    
    /**
     * @dev Get total amount tipped by an address
     * @param tipper The tipper's address
     * @return The total amount tipped
     */
    function getTipperTotal(address tipper) external view returns (uint256) {
        return tipperTotalAmount[tipper];
    }
    
    /**
     * @dev Get recent tips
     * @param count The number of recent tips to retrieve
     * @return Array of recent tips
     */
    function getRecentTips(uint256 count) external view returns (Tip[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 actualCount = count > tipCount ? tipCount : count;
        Tip[] memory recentTips = new Tip[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            recentTips[i] = tips[tipCount - i];
        }
        
        return recentTips;
    }
    
    /**
     * @dev Get all tips
     * @return Array of all tips
     */
    function getAllTips() external view returns (Tip[] memory) {
        Tip[] memory allTips = new Tip[](tipCount);
        
        for (uint256 i = 1; i <= tipCount; i++) {
            allTips[i - 1] = tips[i];
        }
        
        return allTips;
    }
    
    /**
     * @dev Get top tippers
     * @param count The number of top tippers to retrieve
     * @return topTipperAddresses Array of top tipper addresses
     * @return topTipperAmounts Array of corresponding tip amounts
     */
    function getTopTippers(uint256 count) external view returns (
        address[] memory topTipperAddresses,
        uint256[] memory topTipperAmounts
    ) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 actualCount = count > tippers.length ? tippers.length : count;
        
        // Create temporary arrays for sorting
        address[] memory tempAddresses = new address[](tippers.length);
        uint256[] memory tempAmounts = new uint256[](tippers.length);
        
        for (uint256 i = 0; i < tippers.length; i++) {
            tempAddresses[i] = tippers[i];
            tempAmounts[i] = tipperTotalAmount[tippers[i]];
        }
        
        // Simple bubble sort to find top tippers
        for (uint256 i = 0; i < tippers.length; i++) {
            for (uint256 j = i + 1; j < tippers.length; j++) {
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
        topTipperAddresses = new address[](actualCount);
        topTipperAmounts = new uint256[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            topTipperAddresses[i] = tempAddresses[i];
            topTipperAmounts[i] = tempAmounts[i];
        }
        
        return (topTipperAddresses, topTipperAmounts);
    }
    
    /**
     * @dev Get the number of unique tippers
     * @return The number of unique tippers
     */
    function getUniqueTipperCount() external view returns (uint256) {
        return tippers.length;
    }
    
    /**
     * @dev Get tip jar statistics
     * @return totalAmount Total tips received
     * @return totalCount Total number of tips
     * @return uniqueTippers Number of unique tippers
     * @return currentBalance Current contract balance
     */
    function getStats() external view returns (
        uint256 totalAmount,
        uint256 totalCount,
        uint256 uniqueTippers,
        uint256 currentBalance
    ) {
        return (
            totalTipsReceived,
            tipCount,
            tippers.length,
            address(this).balance
        );
    }
    
    /**
     * @dev Get the current balance of the tip jar
     * @return The contract's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get caller's total tips sent
     * @return The total amount the caller has tipped
     */
    function getMyTotalTips() external view returns (uint256) {
        return tipperTotalAmount[msg.sender];
    }
    
    /**
     * @dev Get caller's tip IDs
     * @return Array of tip IDs from the caller
     */
    function getMyTips() external view returns (uint256[] memory) {
        return tipperTipIds[msg.sender];
    }
    
    /**
     * @dev Change the creator address
     * @param newCreator The address of the new creator
     */
    function changeCreator(address payable newCreator) external {
        require(msg.sender == creator, "Only creator can change creator");
        require(newCreator != address(0), "Invalid creator address");
        require(newCreator != creator, "New creator is the same as current");
        
        address oldCreator = creator;
        creator = newCreator;
        
        emit CreatorChanged(oldCreator, newCreator);
    }
    
    /**
     * @dev Receive ETH directly (treated as a tip without message)
     */
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipCount++;
        uint256 tipId = tipCount;
        
        tips[tipId] = Tip({
            id: tipId,
            tipper: msg.sender,
            amount: msg.value,
            message: "",
            timestamp: block.timestamp
        });
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipId);
        
        if (!hasTipped[msg.sender]) {
            hasTipped[msg.sender] = true;
            tippers.push(msg.sender);
        }
        
        emit TipReceived(tipId, msg.sender, msg.value, "", block.timestamp);
    }
    
    /**
     * @dev Fallback function to receive ETH
     */
    fallback() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipCount++;
        uint256 tipId = tipCount;
        
        tips[tipId] = Tip({
            id: tipId,
            tipper: msg.sender,
            amount: msg.value,
            message: "",
            timestamp: block.timestamp
        });
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipId);
        
        if (!hasTipped[msg.sender]) {
            hasTipped[msg.sender] = true;
            tippers.push(msg.sender);
        }
        
        emit TipReceived(tipId, msg.sender, msg.value, "", block.timestamp);
    }
}
