// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTipsReceived;
    uint256 public tipCount;
    
    struct Tip {
        address tipper;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    Tip[] public tips;
    mapping(address => uint256) public tipperTotalAmount;
    mapping(address => uint256) public tipperCount;
    
    event TipReceived(address indexed tipper, uint256 amount, string message, uint256 timestamp);
    event TipsWithdrawn(address indexed creator, uint256 amount);
    event CreatorUpdated(address indexed oldCreator, address indexed newCreator);
    
    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call this function");
        _;
    }
    
    constructor() {
        creator = payable(msg.sender);
    }
    
    function sendTip(string memory _message) external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        }));
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperCount[msg.sender]++;
        tipCount++;
        
        emit TipReceived(msg.sender, msg.value, _message, block.timestamp);
    }
    
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            message: "",
            timestamp: block.timestamp
        }));
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperCount[msg.sender]++;
        tipCount++;
        
        emit TipReceived(msg.sender, msg.value, "", block.timestamp);
    }
    
    function withdrawTips() external onlyCreator {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        (bool success, ) = creator.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, balance);
    }
    
    function withdrawAmount(uint256 _amount) external onlyCreator {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = creator.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, _amount);
    }
    
    function getTip(uint256 _index) external view returns (
        address tipper,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(_index < tips.length, "Invalid tip index");
        Tip memory tip = tips[_index];
        
        return (
            tip.tipper,
            tip.amount,
            tip.message,
            tip.timestamp
        );
    }
    
    function getRecentTips(uint256 _count) external view returns (Tip[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > tips.length ? tips.length : _count;
        Tip[] memory recentTips = new Tip[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentTips[i] = tips[tips.length - 1 - i];
        }
        
        return recentTips;
    }
    
    function getAllTips() external view returns (Tip[] memory) {
        return tips;
    }
    
    function getTipperInfo(address _tipper) external view returns (
        uint256 totalAmount,
        uint256 numberOfTips
    ) {
        return (
            tipperTotalAmount[_tipper],
            tipperCount[_tipper]
        );
    }
    
    function getTopTippers(uint256 _count) external view returns (address[] memory, uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        // This is a simplified implementation
        // For production, consider using off-chain indexing for efficiency
        uint256 count = _count > tipCount ? tipCount : _count;
        address[] memory topTippers = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        
        return (topTippers, amounts);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getTotalTipsReceived() external view returns (uint256) {
        return totalTipsReceived;
    }
    
    function getTipCount() external view returns (uint256) {
        return tipCount;
    }
    
    function getAverageTipAmount() external view returns (uint256) {
        if (tipCount == 0) {
            return 0;
        }
        return totalTipsReceived / tipCount;
    }
    
    function updateCreator(address payable _newCreator) external onlyCreator {
        require(_newCreator != address(0), "New creator cannot be zero address");
        require(_newCreator != creator, "New creator is the same as current creator");
        
        address oldCreator = creator;
        creator = _newCreator;
        
        emit CreatorUpdated(oldCreator, _newCreator);
    }
}
