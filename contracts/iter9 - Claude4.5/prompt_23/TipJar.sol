// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public creator;
    uint256 public totalTips;
    uint256 public tipCount;
    
    mapping(address => uint256) public tipperToAmount;
    mapping(uint256 => Tip) public tips;
    
    struct Tip {
        address tipper;
        uint256 amount;
        uint256 timestamp;
    }
    
    event TipReceived(address indexed tipper, uint256 amount, uint256 timestamp);
    event TipsWithdrawn(address indexed creator, uint256 amount);
    
    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call this function");
        _;
    }
    
    constructor() {
        creator = msg.sender;
        totalTips = 0;
        tipCount = 0;
    }
    
    function sendTip() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipperToAmount[msg.sender] += msg.value;
        totalTips += msg.value;
        
        tips[tipCount] = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });
        
        tipCount++;
        
        emit TipReceived(msg.sender, msg.value, block.timestamp);
    }
    
    function withdrawTips() external onlyCreator {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        payable(creator).transfer(balance);
        emit TipsWithdrawn(creator, balance);
    }
    
    function getTipperAmount(address tipper) external view returns (uint256) {
        return tipperToAmount[tipper];
    }
    
    function getTip(uint256 tipIndex) external view returns (address tipper, uint256 amount, uint256 timestamp) {
        require(tipIndex < tipCount, "Tip index out of bounds");
        Tip memory tip = tips[tipIndex];
        return (tip.tipper, tip.amount, tip.timestamp);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getAllTips() external view returns (Tip[] memory) {
        Tip[] memory allTips = new Tip[](tipCount);
        for (uint256 i = 0; i < tipCount; i++) {
            allTips[i] = tips[i];
        }
        return allTips;
    }
    
    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipperToAmount[msg.sender] += msg.value;
        totalTips += msg.value;
        
        tips[tipCount] = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });
        
        tipCount++;
        
        emit TipReceived(msg.sender, msg.value, block.timestamp);
    }
    
    fallback() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        tipperToAmount[msg.sender] += msg.value;
        totalTips += msg.value;
        
        tips[tipCount] = Tip({
            tipper: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });
        
        tipCount++;
        
        emit TipReceived(msg.sender, msg.value, block.timestamp);
    }
}