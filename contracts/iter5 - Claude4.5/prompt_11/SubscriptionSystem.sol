// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionSystem {
    address public owner;
    uint256 public monthlyPrice;
    uint256 public constant MONTH_DURATION = 30 days;
    
    struct Subscription {
        uint256 expiryTimestamp;
        bool isActive;
    }
    
    mapping(address => Subscription) public subscriptions;
    
    event SubscriptionPurchased(address indexed user, uint256 expiryTimestamp);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTimestamp);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _monthlyPrice) {
        require(_monthlyPrice > 0, "Price must be greater than zero");
        owner = msg.sender;
        monthlyPrice = _monthlyPrice;
    }
    
    function subscribe() external payable {
        require(msg.value == monthlyPrice, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        if (sub.isActive && block.timestamp < sub.expiryTimestamp) {
            // Extend existing subscription
            sub.expiryTimestamp += MONTH_DURATION;
            emit SubscriptionRenewed(msg.sender, sub.expiryTimestamp);
        } else {
            // New subscription or expired subscription
            sub.expiryTimestamp = block.timestamp + MONTH_DURATION;
            sub.isActive = true;
            emit SubscriptionPurchased(msg.sender, sub.expiryTimestamp);
        }
    }
    
    function renewSubscription() external payable {
        require(msg.value == monthlyPrice, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        if (sub.isActive && block.timestamp < sub.expiryTimestamp) {
            sub.expiryTimestamp += MONTH_DURATION;
        } else {
            sub.expiryTimestamp = block.timestamp + MONTH_DURATION;
            sub.isActive = true;
        }
        
        emit SubscriptionRenewed(msg.sender, sub.expiryTimestamp);
    }
    
    function isSubscriptionActive(address _user) public view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        return sub.isActive && block.timestamp < sub.expiryTimestamp;
    }
    
    function getSubscriptionExpiry(address _user) external view returns (uint256) {
        return subscriptions[_user].expiryTimestamp;
    }
    
    function timeUntilExpiry(address _user) external view returns (uint256) {
        Subscription memory sub = subscriptions[_user];
        
        if (!sub.isActive || block.timestamp >= sub.expiryTimestamp) {
            return 0;
        }
        
        return sub.expiryTimestamp - block.timestamp;
    }
    
    function updatePrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price must be greater than zero");
        
        uint256 oldPrice = monthlyPrice;
        monthlyPrice = _newPrice;
        
        emit PriceUpdated(oldPrice, _newPrice);
    }
    
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
