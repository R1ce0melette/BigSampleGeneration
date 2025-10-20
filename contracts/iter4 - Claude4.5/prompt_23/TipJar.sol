// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TipJar
 * @dev A contract for a tip jar where users can send ETH to a creator and track total tips received
 */
contract TipJar {
    address payable public creator;
    
    struct Tip {
        address tipper;
        uint256 amount;
        uint256 timestamp;
        string message;
    }
    
    uint256 public tipCount;
    uint256 public totalTipsReceived;
    
    mapping(uint256 => Tip) public tips;
    mapping(address => uint256) public tipperTotalAmount;
    mapping(address => uint256[]) public tipperTipIds;
    
    // Events
    event TipReceived(uint256 indexed tipId, address indexed tipper, uint256 amount, string message, uint256 timestamp);
    event TipsWithdrawn(address indexed creator, uint256 amount, uint256 timestamp);
    event CreatorUpdated(address indexed oldCreator, address indexed newCreator);
    
    /**
     * @dev Constructor to set the creator
     * @param _creator The address of the creator
     */
    constructor(address payable _creator) {
        require(_creator != address(0), "Invalid creator address");
        creator = _creator;
    }
    
    /**
     * @dev Allows anyone to send a tip to the creator
     * @param _message Optional message with the tip
     */
    function sendTip(string memory _message) external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipCount++;
        totalTipsReceived += msg.value;
        
        tips[tipCount] = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: _message
        });
        
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipCount);
        
        emit TipReceived(tipCount, msg.sender, msg.value, _message, block.timestamp);
    }
    
    /**
     * @dev Allows the creator to withdraw all tips
     */
    function withdrawAll() external {
        require(msg.sender == creator, "Only creator can withdraw");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        (bool success, ) = creator.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, balance, block.timestamp);
    }
    
    /**
     * @dev Allows the creator to withdraw a specific amount
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == creator, "Only creator can withdraw");
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = creator.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, _amount, block.timestamp);
    }
    
    /**
     * @dev Returns the details of a specific tip
     * @param _tipId The ID of the tip
     * @return tipper The tipper's address
     * @return amount The tip amount
     * @return timestamp When the tip was sent
     * @return message The message with the tip
     */
    function getTip(uint256 _tipId) external view returns (
        address tipper,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(_tipId > 0 && _tipId <= tipCount, "Invalid tip ID");
        
        Tip memory tip = tips[_tipId];
        
        return (
            tip.tipper,
            tip.amount,
            tip.timestamp,
            tip.message
        );
    }
    
    /**
     * @dev Returns all tips (use with caution for large datasets)
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
     * @dev Returns the latest N tips
     * @param _count The number of recent tips to retrieve
     * @return Array of recent tips
     */
    function getRecentTips(uint256 _count) external view returns (Tip[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > tipCount ? tipCount : _count;
        Tip[] memory recentTips = new Tip[](count);
        
        uint256 startIndex = tipCount - count + 1;
        
        for (uint256 i = 0; i < count; i++) {
            recentTips[i] = tips[startIndex + i];
        }
        
        return recentTips;
    }
    
    /**
     * @dev Returns all tips from a specific tipper
     * @param _tipper The address of the tipper
     * @return Array of tip IDs
     */
    function getTipsByTipper(address _tipper) external view returns (uint256[] memory) {
        return tipperTipIds[_tipper];
    }
    
    /**
     * @dev Returns the total amount tipped by a specific tipper
     * @param _tipper The address of the tipper
     * @return The total amount tipped
     */
    function getTipperTotalAmount(address _tipper) external view returns (uint256) {
        return tipperTotalAmount[_tipper];
    }
    
    /**
     * @dev Returns the caller's total tip amount
     * @return The total amount tipped by the caller
     */
    function getMyTotalTips() external view returns (uint256) {
        return tipperTotalAmount[msg.sender];
    }
    
    /**
     * @dev Returns the caller's tip IDs
     * @return Array of tip IDs
     */
    function getMyTips() external view returns (uint256[] memory) {
        return tipperTipIds[msg.sender];
    }
    
    /**
     * @dev Returns the current balance in the tip jar
     * @return The current balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the total number of tips
     * @return The tip count
     */
    function getTotalTipCount() external view returns (uint256) {
        return tipCount;
    }
    
    /**
     * @dev Returns the top tippers
     * @param _limit The maximum number of top tippers to return
     * @return tippers Array of tipper addresses
     * @return amounts Array of corresponding tip amounts
     */
    function getTopTippers(uint256 _limit) external view returns (address[] memory tippers, uint256[] memory amounts) {
        require(_limit > 0, "Limit must be greater than 0");
        
        // Get unique tippers
        address[] memory uniqueTippers = new address[](tipCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 1; i <= tipCount; i++) {
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
        
        // Determine actual limit
        uint256 actualLimit = _limit > uniqueCount ? uniqueCount : _limit;
        
        tippers = new address[](actualLimit);
        amounts = new uint256[](actualLimit);
        
        // Simple selection sort for top tippers
        for (uint256 i = 0; i < actualLimit; i++) {
            uint256 maxAmount = 0;
            address maxTipper = address(0);
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (tipperTotalAmount[uniqueTippers[j]] > maxAmount) {
                    maxAmount = tipperTotalAmount[uniqueTippers[j]];
                    maxTipper = uniqueTippers[j];
                    maxIndex = j;
                }
            }
            
            if (maxTipper != address(0)) {
                tippers[i] = maxTipper;
                amounts[i] = maxAmount;
                uniqueTippers[maxIndex] = address(0);
            }
        }
        
        return (tippers, amounts);
    }
    
    /**
     * @dev Returns statistics about the tip jar
     * @return totalTips Total number of tips
     * @return totalAmount Total amount received
     * @return currentBalance Current balance in contract
     * @return totalWithdrawn Total amount withdrawn
     */
    function getStatistics() external view returns (
        uint256 totalTips,
        uint256 totalAmount,
        uint256 currentBalance,
        uint256 totalWithdrawn
    ) {
        uint256 balance = address(this).balance;
        uint256 withdrawn = totalTipsReceived - balance;
        
        return (
            tipCount,
            totalTipsReceived,
            balance,
            withdrawn
        );
    }
    
    /**
     * @dev Allows the creator to update the creator address
     * @param _newCreator The address of the new creator
     */
    function updateCreator(address payable _newCreator) external {
        require(msg.sender == creator, "Only creator can update");
        require(_newCreator != address(0), "Invalid creator address");
        require(_newCreator != creator, "New creator must be different");
        
        address oldCreator = creator;
        creator = _newCreator;
        
        emit CreatorUpdated(oldCreator, _newCreator);
    }
    
    /**
     * @dev Fallback function to receive tips without message
     */
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipCount++;
        totalTipsReceived += msg.value;
        
        tips[tipCount] = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: ""
        });
        
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipCount);
        
        emit TipReceived(tipCount, msg.sender, msg.value, "", block.timestamp);
    }
}
