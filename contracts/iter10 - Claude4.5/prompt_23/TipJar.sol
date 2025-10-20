// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address payable public creator;
    uint256 public totalTips;
    uint256 public tipCount;

    struct Tip {
        address tipper;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    Tip[] public tips;
    mapping(address => uint256) public tipperTotalAmount;
    mapping(address => uint256) public tipperTipCount;

    event TipReceived(address indexed tipper, uint256 amount, string message, uint256 timestamp);
    event TipsWithdrawn(address indexed creator, uint256 amount);

    constructor() {
        creator = payable(msg.sender);
    }

    function sendTip(string memory message) external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            message: message,
            timestamp: block.timestamp
        }));

        totalTips += msg.value;
        tipCount++;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipCount[msg.sender]++;

        emit TipReceived(msg.sender, msg.value, message, block.timestamp);
    }

    function withdrawTips() external {
        require(msg.sender == creator, "Only creator can withdraw tips");
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");

        (bool success, ) = creator.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit TipsWithdrawn(creator, balance);
    }

    function withdrawPartialTips(uint256 amount) external {
        require(msg.sender == creator, "Only creator can withdraw tips");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = creator.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit TipsWithdrawn(creator, amount);
    }

    function getTip(uint256 index) external view returns (
        address tipper,
        uint256 amount,
        string memory message,
        uint256 timestamp
    ) {
        require(index < tips.length, "Tip does not exist");
        Tip memory tip = tips[index];
        return (tip.tipper, tip.amount, tip.message, tip.timestamp);
    }

    function getLatestTips(uint256 count) external view returns (Tip[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > tips.length ? tips.length : count;
        Tip[] memory latestTips = new Tip[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            latestTips[i] = tips[tips.length - 1 - i];
        }

        return latestTips;
    }

    function getAllTips() external view returns (Tip[] memory) {
        return tips;
    }

    function getTipperTotal(address tipper) external view returns (uint256) {
        return tipperTotalAmount[tipper];
    }

    function getTipperCount(address tipper) external view returns (uint256) {
        return tipperTipCount[tipper];
    }

    function getTopTippers(uint256 count) external view returns (address[] memory, uint256[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        // Get unique tippers
        address[] memory uniqueTippers = new address[](tips.length);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < tips.length; i++) {
            address tipper = tips[i].tipper;
            bool isUnique = true;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueTippers[j] == tipper) {
                    isUnique = false;
                    break;
                }
            }
            
            if (isUnique) {
                uniqueTippers[uniqueCount] = tipper;
                uniqueCount++;
            }
        }

        uint256 resultCount = count > uniqueCount ? uniqueCount : count;
        address[] memory topTippers = new address[](resultCount);
        uint256[] memory topAmounts = new uint256[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 maxAmount = 0;
            uint256 maxIndex = 0;
            
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (tipperTotalAmount[uniqueTippers[j]] > maxAmount) {
                    bool alreadyAdded = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (topTippers[k] == uniqueTippers[j]) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    if (!alreadyAdded) {
                        maxAmount = tipperTotalAmount[uniqueTippers[j]];
                        maxIndex = j;
                    }
                }
            }
            
            topTippers[i] = uniqueTippers[maxIndex];
            topAmounts[i] = maxAmount;
        }

        return (topTippers, topAmounts);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function changeCreator(address payable newCreator) external {
        require(msg.sender == creator, "Only creator can change creator");
        require(newCreator != address(0), "Invalid creator address");
        creator = newCreator;
    }

    receive() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        tips.push(Tip({
            tipper: msg.sender,
            amount: msg.value,
            message: "",
            timestamp: block.timestamp
        }));

        totalTips += msg.value;
        tipCount++;
        tipperTotalAmount[msg.sender] += msg.value;
        tipperTipCount[msg.sender]++;

        emit TipReceived(msg.sender, msg.value, "", block.timestamp);
    }
}
