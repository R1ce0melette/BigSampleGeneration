// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionSystem {
    address public owner;
    uint256 public monthlyFee;
    
    struct Subscription {
        uint256 startTime;
        uint256 expiryTime;
        bool isActive;
    }
    
    mapping(address => Subscription) public subscriptions;
    
    event Subscribed(address indexed user, uint256 startTime, uint256 expiryTime);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime);
    event SubscriptionCancelled(address indexed user);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event Withdrawal(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }
    
    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        if (sub.isActive && block.timestamp < sub.expiryTime) {
            // Extend existing subscription
            sub.expiryTime += 30 days;
            emit SubscriptionRenewed(msg.sender, sub.expiryTime);
        } else {
            // New subscription
            sub.startTime = block.timestamp;
            sub.expiryTime = block.timestamp + 30 days;
            sub.isActive = true;
            emit Subscribed(msg.sender, sub.startTime, sub.expiryTime);
        }
    }
    
    function renewSubscription() external payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee");
        Subscription storage sub = subscriptions[msg.sender];
        require(sub.isActive, "No active subscription to renew");
        
        if (block.timestamp < sub.expiryTime) {
            sub.expiryTime += 30 days;
        } else {
            sub.expiryTime = block.timestamp + 30 days;
        }
        
        emit SubscriptionRenewed(msg.sender, sub.expiryTime);
    }
    
    function cancelSubscription() external {
        Subscription storage sub = subscriptions[msg.sender];
        require(sub.isActive, "No active subscription");
        
        sub.isActive = false;
        
        emit SubscriptionCancelled(msg.sender);
    }
    
    function isSubscriptionActive(address _user) public view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        return sub.isActive && block.timestamp < sub.expiryTime;
    }
    
    function getSubscriptionInfo(address _user) external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool isActive,
        bool isCurrentlyValid,
        uint256 daysRemaining
    ) {
        Subscription memory sub = subscriptions[_user];
        bool currentlyValid = isSubscriptionActive(_user);
        uint256 daysLeft = 0;
        
        if (currentlyValid && sub.expiryTime > block.timestamp) {
            daysLeft = (sub.expiryTime - block.timestamp) / 1 days;
        }
        
        return (
            sub.startTime,
            sub.expiryTime,
            sub.isActive,
            currentlyValid,
            daysLeft
        );
    }
    
    function updateMonthlyFee(uint256 _newFee) external onlyOwner {
        require(_newFee > 0, "Fee must be greater than 0");
        uint256 oldFee = monthlyFee;
        monthlyFee = _newFee;
        
        emit FeeUpdated(oldFee, _newFee);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, balance);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
