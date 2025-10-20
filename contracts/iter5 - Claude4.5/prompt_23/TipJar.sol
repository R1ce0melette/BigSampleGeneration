// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTipsReceived;
    uint256 public tipCount;
    
    struct Tip {
        uint256 id;
        address tipper;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    mapping(uint256 => Tip) public tips;
    mapping(address => uint256) public tipperTotalAmount;
    mapping(address => uint256[]) public tipperTipIds;
    
    event TipReceived(uint256 indexed tipId, address indexed tipper, uint256 amount, string message, uint256 timestamp);
    event TipsWithdrawn(address indexed creator, uint256 amount);
    
    constructor() {
        creator = payable(msg.sender);
    }
    
    function sendTip(string memory _message) external payable {
        require(msg.value > 0, "Tip must be greater than zero");
        
        tipCount++;
        
        tips[tipCount] = Tip({
            id: tipCount,
            tipper: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        });
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipCount);
        
        emit TipReceived(tipCount, msg.sender, msg.value, _message, block.timestamp);
    }
    
    function withdrawTips() external {
        require(msg.sender == creator, "Only creator can withdraw tips");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");
        
        (bool success, ) = creator.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, balance);
    }
    
    function withdrawAmount(uint256 _amount) external {
        require(msg.sender == creator, "Only creator can withdraw tips");
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = creator.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit TipsWithdrawn(creator, _amount);
    }
    
    function getTip(uint256 _tipId) external view returns (
        uint256 id,
        address tipper,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(_tipId > 0 && _tipId <= tipCount, "Tip does not exist");
        
        Tip memory tip = tips[_tipId];
        
        return (
            tip.id,
            tip.tipper,
            tip.amount,
            tip.message,
            tip.timestamp
        );
    }
    
    function getAllTips() external view returns (Tip[] memory) {
        Tip[] memory allTips = new Tip[](tipCount);
        
        for (uint256 i = 1; i <= tipCount; i++) {
            allTips[i - 1] = tips[i];
        }
        
        return allTips;
    }
    
    function getTipperTips(address _tipper) external view returns (uint256[] memory) {
        return tipperTipIds[_tipper];
    }
    
    function getTipperTotalAmount(address _tipper) external view returns (uint256) {
        return tipperTotalAmount[_tipper];
    }
    
    function getRecentTips(uint256 _count) external view returns (Tip[] memory) {
        uint256 count = _count;
        if (count > tipCount) {
            count = tipCount;
        }
        
        Tip[] memory recentTips = new Tip[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentTips[i] = tips[tipCount - i];
        }
        
        return recentTips;
    }
    
    function getTopTippers(uint256 _count) external view returns (address[] memory, uint256[] memory) {
        uint256 count = _count;
        if (count > tipCount) {
            count = tipCount;
        }
        
        address[] memory tippers = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        
        // Collect all unique tippers
        address[] memory allTippers = new address[](tipCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 1; i <= tipCount; i++) {
            address tipper = tips[i].tipper;
            bool found = false;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (allTippers[j] == tipper) {
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                allTippers[uniqueCount] = tipper;
                uniqueCount++;
            }
        }
        
        // Simple bubble sort to get top tippers
        for (uint256 i = 0; i < uniqueCount && i < count; i++) {
            uint256 maxAmount = 0;
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (tipperTotalAmount[allTippers[j]] > maxAmount) {
                    bool alreadyAdded = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (tippers[k] == allTippers[j]) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    
                    if (!alreadyAdded) {
                        maxAmount = tipperTotalAmount[allTippers[j]];
                        maxIndex = j;
                    }
                }
            }
            
            tippers[i] = allTippers[maxIndex];
            amounts[i] = maxAmount;
        }
        
        return (tippers, amounts);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        tipCount++;
        
        tips[tipCount] = Tip({
            id: tipCount,
            tipper: msg.sender,
            amount: msg.value,
            message: "Anonymous tip",
            timestamp: block.timestamp
        });
        
        totalTipsReceived += msg.value;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipIds[msg.sender].push(tipCount);
        
        emit TipReceived(tipCount, msg.sender, msg.value, "Anonymous tip", block.timestamp);
    }
}
