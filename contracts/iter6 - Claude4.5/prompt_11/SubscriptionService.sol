// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionService
 * @dev A basic subscription system where users pay ETH for monthly access
 */
contract SubscriptionService {
    address public owner;
    uint256 public monthlyFee;
    
    struct Subscription {
        uint256 startTime;
        uint256 expiryTime;
        bool isActive;
    }
    
    mapping(address => Subscription) public subscriptions;
    
    uint256 public constant MONTH_DURATION = 30 days;
    uint256 public totalSubscribers;
    uint256 public activeSubscribers;
    
    // Events
    event Subscribed(address indexed user, uint256 startTime, uint256 expiryTime);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime);
    event SubscriptionCancelled(address indexed user);
    event MonthlyFeeUpdated(uint256 oldFee, uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyActiveSubscriber() {
        require(isSubscriptionActive(msg.sender), "No active subscription");
        _;
    }
    
    constructor(uint256 _monthlyFee) {
        require(_monthlyFee > 0, "Monthly fee must be greater than 0");
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }
    
    /**
     * @dev Subscribe to the service for one month
     */
    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        if (sub.startTime == 0) {
            // New subscriber
            totalSubscribers++;
            sub.startTime = block.timestamp;
            sub.expiryTime = block.timestamp + MONTH_DURATION;
            sub.isActive = true;
            activeSubscribers++;
            
            emit Subscribed(msg.sender, sub.startTime, sub.expiryTime);
        } else {
            // Renewing or reactivating subscription
            if (!sub.isActive) {
                activeSubscribers++;
            }
            
            // If subscription is still active, extend from expiry time
            // Otherwise, start from current time
            if (sub.expiryTime > block.timestamp) {
                sub.expiryTime += MONTH_DURATION;
            } else {
                sub.expiryTime = block.timestamp + MONTH_DURATION;
            }
            
            sub.isActive = true;
            
            emit SubscriptionRenewed(msg.sender, sub.expiryTime);
        }
    }
    
    /**
     * @dev Subscribe for multiple months at once
     * @param months The number of months to subscribe for
     */
    function subscribeMultipleMonths(uint256 months) external payable {
        require(months > 0, "Must subscribe for at least 1 month");
        require(msg.value == monthlyFee * months, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        if (sub.startTime == 0) {
            // New subscriber
            totalSubscribers++;
            sub.startTime = block.timestamp;
            sub.expiryTime = block.timestamp + (MONTH_DURATION * months);
            sub.isActive = true;
            activeSubscribers++;
            
            emit Subscribed(msg.sender, sub.startTime, sub.expiryTime);
        } else {
            // Renewing or reactivating subscription
            if (!sub.isActive) {
                activeSubscribers++;
            }
            
            // If subscription is still active, extend from expiry time
            // Otherwise, start from current time
            if (sub.expiryTime > block.timestamp) {
                sub.expiryTime += (MONTH_DURATION * months);
            } else {
                sub.expiryTime = block.timestamp + (MONTH_DURATION * months);
            }
            
            sub.isActive = true;
            
            emit SubscriptionRenewed(msg.sender, sub.expiryTime);
        }
    }
    
    /**
     * @dev Cancel subscription (does not refund)
     */
    function cancelSubscription() external onlyActiveSubscriber {
        Subscription storage sub = subscriptions[msg.sender];
        sub.isActive = false;
        activeSubscribers--;
        
        emit SubscriptionCancelled(msg.sender);
    }
    
    /**
     * @dev Check if a user has an active subscription
     * @param user The address to check
     * @return True if subscription is active, false otherwise
     */
    function isSubscriptionActive(address user) public view returns (bool) {
        Subscription memory sub = subscriptions[user];
        return sub.isActive && sub.expiryTime > block.timestamp;
    }
    
    /**
     * @dev Get subscription details for a user
     * @param user The address to query
     * @return startTime The subscription start time
     * @return expiryTime The subscription expiry time
     * @return isActive Whether the subscription is active
     * @return daysRemaining Days remaining in subscription
     */
    function getSubscriptionDetails(address user) external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool isActive,
        uint256 daysRemaining
    ) {
        Subscription memory sub = subscriptions[user];
        uint256 remaining = 0;
        
        if (sub.isActive && sub.expiryTime > block.timestamp) {
            remaining = (sub.expiryTime - block.timestamp) / 1 days;
        }
        
        return (
            sub.startTime,
            sub.expiryTime,
            sub.isActive && sub.expiryTime > block.timestamp,
            remaining
        );
    }
    
    /**
     * @dev Get the caller's subscription details
     * @return startTime The subscription start time
     * @return expiryTime The subscription expiry time
     * @return isActive Whether the subscription is active
     * @return daysRemaining Days remaining in subscription
     */
    function getMySubscription() external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool isActive,
        uint256 daysRemaining
    ) {
        Subscription memory sub = subscriptions[msg.sender];
        uint256 remaining = 0;
        
        if (sub.isActive && sub.expiryTime > block.timestamp) {
            remaining = (sub.expiryTime - block.timestamp) / 1 days;
        }
        
        return (
            sub.startTime,
            sub.expiryTime,
            sub.isActive && sub.expiryTime > block.timestamp,
            remaining
        );
    }
    
    /**
     * @dev Get time remaining until subscription expires
     * @param user The address to check
     * @return The time remaining in seconds, or 0 if expired
     */
    function getTimeRemaining(address user) external view returns (uint256) {
        Subscription memory sub = subscriptions[user];
        
        if (!sub.isActive || sub.expiryTime <= block.timestamp) {
            return 0;
        }
        
        return sub.expiryTime - block.timestamp;
    }
    
    /**
     * @dev Update the monthly fee (owner only)
     * @param newFee The new monthly fee in wei
     */
    function updateMonthlyFee(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Fee must be greater than 0");
        
        uint256 oldFee = monthlyFee;
        monthlyFee = newFee;
        
        emit MonthlyFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev Withdraw collected fees (owner only)
     * @param amount The amount to withdraw (0 to withdraw all)
     */
    function withdrawFunds(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        uint256 withdrawAmount = amount == 0 ? balance : amount;
        require(withdrawAmount <= balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: withdrawAmount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, withdrawAmount);
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get subscription statistics
     * @return _totalSubscribers Total number of unique subscribers
     * @return _activeSubscribers Number of currently active subscribers
     * @return _monthlyFee Current monthly fee
     * @return _contractBalance Contract's ETH balance
     */
    function getStats() external view returns (
        uint256 _totalSubscribers,
        uint256 _activeSubscribers,
        uint256 _monthlyFee,
        uint256 _contractBalance
    ) {
        return (
            totalSubscribers,
            activeSubscribers,
            monthlyFee,
            address(this).balance
        );
    }
}
