// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TipJar
 * @dev Contract for a tip jar where users can send ETH to a creator and the contract keeps track of total tips received
 */
contract TipJar {
    // Tip structure
    struct Tip {
        uint256 id;
        address tipper;
        uint256 amount;
        uint256 timestamp;
        string message;
    }

    // Tipper statistics
    struct TipperStats {
        uint256 totalTipped;
        uint256 tipCount;
        uint256 firstTipTime;
        uint256 lastTipTime;
    }

    // State variables
    address public creator;
    string public creatorName;
    string public description;
    
    uint256 private tipCounter;
    uint256 public totalTipsReceived;
    uint256 public totalTipAmount;
    uint256 public totalWithdrawn;
    
    mapping(uint256 => Tip) private tips;
    mapping(address => uint256[]) private tipperTipIds;
    mapping(address => TipperStats) private tipperStats;
    mapping(address => bool) private hasTipped;
    
    uint256[] private allTipIds;
    address[] private allTippers;

    // Events
    event TipReceived(uint256 indexed tipId, address indexed tipper, uint256 amount, uint256 timestamp);
    event FundsWithdrawn(address indexed creator, uint256 amount, uint256 timestamp);
    event CreatorUpdated(address indexed oldCreator, address indexed newCreator);
    event InfoUpdated(string name, string description);

    // Modifiers
    modifier onlyCreator() {
        require(msg.sender == creator, "Not the creator");
        _;
    }

    constructor(
        address _creator,
        string memory _creatorName,
        string memory _description
    ) {
        require(_creator != address(0), "Invalid creator address");
        
        creator = _creator;
        creatorName = _creatorName;
        description = _description;
        tipCounter = 0;
        totalTipsReceived = 0;
        totalTipAmount = 0;
        totalWithdrawn = 0;
    }

    /**
     * @dev Send a tip with a message
     * @param message Optional message with the tip
     */
    function sendTip(string memory message) public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        tipCounter++;
        uint256 tipId = tipCounter;

        Tip memory newTip = Tip({
            id: tipId,
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: message
        });

        tips[tipId] = newTip;
        tipperTipIds[msg.sender].push(tipId);
        allTipIds.push(tipId);

        // Track new tippers
        if (!hasTipped[msg.sender]) {
            hasTipped[msg.sender] = true;
            allTippers.push(msg.sender);
            tipperStats[msg.sender].firstTipTime = block.timestamp;
        }

        // Update tipper stats
        TipperStats storage stats = tipperStats[msg.sender];
        stats.totalTipped += msg.value;
        stats.tipCount++;
        stats.lastTipTime = block.timestamp;

        // Update total stats
        totalTipsReceived++;
        totalTipAmount += msg.value;

        emit TipReceived(tipId, msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Send a tip without a message
     */
    function sendTip() public payable {
        sendTip("");
    }

    /**
     * @dev Withdraw tips to creator
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) public onlyCreator {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");

        totalWithdrawn += amount;
        payable(creator).transfer(amount);

        emit FundsWithdrawn(creator, amount, block.timestamp);
    }

    /**
     * @dev Withdraw all tips to creator
     */
    function withdrawAll() public onlyCreator {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        totalWithdrawn += balance;
        payable(creator).transfer(balance);

        emit FundsWithdrawn(creator, balance, block.timestamp);
    }

    /**
     * @dev Get tip details
     * @param tipId Tip ID
     * @return Tip details
     */
    function getTip(uint256 tipId) public view returns (Tip memory) {
        require(tipId > 0 && tipId <= tipCounter, "Tip does not exist");
        return tips[tipId];
    }

    /**
     * @dev Get all tips
     * @return Array of all tips
     */
    function getAllTips() public view returns (Tip[] memory) {
        Tip[] memory allTips = new Tip[](allTipIds.length);
        
        for (uint256 i = 0; i < allTipIds.length; i++) {
            allTips[i] = tips[allTipIds[i]];
        }
        
        return allTips;
    }

    /**
     * @dev Get recent tips
     * @param count Number of recent tips to retrieve
     * @return Array of recent tips
     */
    function getRecentTips(uint256 count) public view returns (Tip[] memory) {
        uint256 totalCount = allTipIds.length;
        uint256 resultCount = count > totalCount ? totalCount : count;

        Tip[] memory result = new Tip[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = tips[allTipIds[totalCount - 1 - i]];
        }

        return result;
    }

    /**
     * @dev Get tips by tipper
     * @param tipper Tipper address
     * @return Array of tips
     */
    function getTipsByTipper(address tipper) public view returns (Tip[] memory) {
        uint256[] memory tipIds = tipperTipIds[tipper];
        Tip[] memory tipperTips = new Tip[](tipIds.length);

        for (uint256 i = 0; i < tipIds.length; i++) {
            tipperTips[i] = tips[tipIds[i]];
        }

        return tipperTips;
    }

    /**
     * @dev Get tipper tip IDs
     * @param tipper Tipper address
     * @return Array of tip IDs
     */
    function getTipperTipIds(address tipper) public view returns (uint256[] memory) {
        return tipperTipIds[tipper];
    }

    /**
     * @dev Get tipper statistics
     * @param tipper Tipper address
     * @return TipperStats structure
     */
    function getTipperStats(address tipper) public view returns (TipperStats memory) {
        return tipperStats[tipper];
    }

    /**
     * @dev Get all tippers
     * @return Array of all tipper addresses
     */
    function getAllTippers() public view returns (address[] memory) {
        return allTippers;
    }

    /**
     * @dev Get top tippers
     * @param count Number of top tippers to retrieve
     * @return Array of tipper addresses
     * @return Array of their total tip amounts
     */
    function getTopTippers(uint256 count) 
        public 
        view 
        returns (address[] memory, uint256[] memory) 
    {
        uint256 resultCount = count > allTippers.length ? allTippers.length : count;
        
        address[] memory topTipperAddresses = new address[](resultCount);
        uint256[] memory topTipperAmounts = new uint256[](resultCount);

        // Create a copy of tippers for sorting
        address[] memory sortedTippers = new address[](allTippers.length);
        for (uint256 i = 0; i < allTippers.length; i++) {
            sortedTippers[i] = allTippers[i];
        }

        // Simple bubble sort for top tippers
        for (uint256 i = 0; i < resultCount && i < sortedTippers.length; i++) {
            for (uint256 j = i + 1; j < sortedTippers.length; j++) {
                if (tipperStats[sortedTippers[j]].totalTipped > tipperStats[sortedTippers[i]].totalTipped) {
                    address temp = sortedTippers[i];
                    sortedTippers[i] = sortedTippers[j];
                    sortedTippers[j] = temp;
                }
            }
        }

        for (uint256 i = 0; i < resultCount; i++) {
            topTipperAddresses[i] = sortedTippers[i];
            topTipperAmounts[i] = tipperStats[sortedTippers[i]].totalTipped;
        }

        return (topTipperAddresses, topTipperAmounts);
    }

    /**
     * @dev Get tips in time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of tips in the time range
     */
    function getTipsInTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Tip[] memory) 
    {
        require(endTime >= startTime, "Invalid time range");

        uint256 count = 0;
        for (uint256 i = 0; i < allTipIds.length; i++) {
            Tip memory tip = tips[allTipIds[i]];
            if (tip.timestamp >= startTime && tip.timestamp <= endTime) {
                count++;
            }
        }

        Tip[] memory result = new Tip[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTipIds.length; i++) {
            Tip memory tip = tips[allTipIds[i]];
            if (tip.timestamp >= startTime && tip.timestamp <= endTime) {
                result[index] = tip;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get tips above amount
     * @param minAmount Minimum tip amount
     * @return Array of tips above the amount
     */
    function getTipsAboveAmount(uint256 minAmount) 
        public 
        view 
        returns (Tip[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allTipIds.length; i++) {
            if (tips[allTipIds[i]].amount >= minAmount) {
                count++;
            }
        }

        Tip[] memory result = new Tip[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTipIds.length; i++) {
            Tip memory tip = tips[allTipIds[i]];
            if (tip.amount >= minAmount) {
                result[index] = tip;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total tip count
     * @return Total number of tips
     */
    function getTotalTipCount() public view returns (uint256) {
        return tipCounter;
    }

    /**
     * @dev Get total tips received
     * @return Total number of tips
     */
    function getTotalTipsReceived() public view returns (uint256) {
        return totalTipsReceived;
    }

    /**
     * @dev Get total tip amount
     * @return Total amount of tips
     */
    function getTotalTipAmount() public view returns (uint256) {
        return totalTipAmount;
    }

    /**
     * @dev Get current balance
     * @return Current jar balance
     */
    function getCurrentBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get total withdrawn
     * @return Total amount withdrawn
     */
    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    /**
     * @dev Get total unique tippers
     * @return Total number of unique tippers
     */
    function getTotalTippers() public view returns (uint256) {
        return allTippers.length;
    }

    /**
     * @dev Get average tip amount
     * @return Average tip amount
     */
    function getAverageTipAmount() public view returns (uint256) {
        if (totalTipsReceived == 0) {
            return 0;
        }
        return totalTipAmount / totalTipsReceived;
    }

    /**
     * @dev Get largest tip
     * @return Largest tip amount
     * @return Tipper address
     * @return Tip ID
     */
    function getLargestTip() 
        public 
        view 
        returns (uint256 amount, address tipper, uint256 tipId) 
    {
        uint256 maxAmount = 0;
        address maxTipper = address(0);
        uint256 maxId = 0;

        for (uint256 i = 0; i < allTipIds.length; i++) {
            Tip memory tip = tips[allTipIds[i]];
            if (tip.amount > maxAmount) {
                maxAmount = tip.amount;
                maxTipper = tip.tipper;
                maxId = tip.id;
            }
        }

        return (maxAmount, maxTipper, maxId);
    }

    /**
     * @dev Check if address has tipped
     * @param tipper Address to check
     * @return true if address has tipped
     */
    function hasAddressTipped(address tipper) public view returns (bool) {
        return hasTipped[tipper];
    }

    /**
     * @dev Get tip jar summary
     * @return creatorAddr Creator address
     * @return name Creator name
     * @return desc Description
     * @return totalTips Total tips count
     * @return totalAmount Total tip amount
     * @return currentBal Current balance
     * @return totalWith Total withdrawn
     * @return tipperCount Total unique tippers
     */
    function getTipJarSummary() 
        public 
        view 
        returns (
            address creatorAddr,
            string memory name,
            string memory desc,
            uint256 totalTips,
            uint256 totalAmount,
            uint256 currentBal,
            uint256 totalWith,
            uint256 tipperCount
        ) 
    {
        return (
            creator,
            creatorName,
            description,
            totalTipsReceived,
            totalTipAmount,
            address(this).balance,
            totalWithdrawn,
            allTippers.length
        );
    }

    /**
     * @dev Update creator address
     * @param newCreator New creator address
     */
    function updateCreator(address newCreator) public onlyCreator {
        require(newCreator != address(0), "Invalid creator address");
        require(newCreator != creator, "Same as current creator");

        address oldCreator = creator;
        creator = newCreator;

        emit CreatorUpdated(oldCreator, newCreator);
    }

    /**
     * @dev Update tip jar information
     * @param newName New creator name
     * @param newDescription New description
     */
    function updateInfo(string memory newName, string memory newDescription) public onlyCreator {
        creatorName = newName;
        description = newDescription;

        emit InfoUpdated(newName, newDescription);
    }

    /**
     * @dev Receive function to accept direct ETH transfers
     */
    receive() external payable {
        sendTip("");
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        sendTip("");
    }
}
