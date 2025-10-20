// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionService
 * @dev A basic subscription system where users pay ETH for monthly access
 */
contract SubscriptionService {
    address public owner;
    uint256 public monthlyFee;
    
    // Subscription structure
    struct Subscription {
        uint256 startTime;
        uint256 expiryTime;
        bool active;
    }
    
    // Mapping to track user subscriptions
    mapping(address => Subscription) public subscriptions;
    
    // Total subscribers count
    uint256 public totalSubscribers;
    
    // Events
    event Subscribed(address indexed user, uint256 startTime, uint256 expiryTime, uint256 amount);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime, uint256 amount);
    event SubscriptionCancelled(address indexed user);
    event MonthlyFeeUpdated(uint256 oldFee, uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier hasActiveSubscription() {
        require(isSubscriptionActive(msg.sender), "No active subscription");
        _;
    }
    
    /**
     * @dev Constructor to initialize the subscription service
     * @param _monthlyFee The monthly subscription fee in wei
     */
    constructor(uint256 _monthlyFee) {
        require(_monthlyFee > 0, "Monthly fee must be greater than 0");
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }
    
    /**
     * @dev Subscribe to the service for one month
     */
    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee");
        require(!isSubscriptionActive(msg.sender), "Already have an active subscription");
        
        uint256 startTime = block.timestamp;
        uint256 expiryTime = startTime + 30 days;
        
        subscriptions[msg.sender] = Subscription({
            startTime: startTime,
            expiryTime: expiryTime,
            active: true
        });
        
        totalSubscribers++;
        
        emit Subscribed(msg.sender, startTime, expiryTime, msg.value);
    }
    
    /**
     * @dev Renew subscription for another month
     */
    function renewSubscription() external payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        // If subscription is still active, extend from current expiry
        // If expired, start new subscription period from now
        uint256 newExpiryTime;
        if (isSubscriptionActive(msg.sender)) {
            newExpiryTime = sub.expiryTime + 30 days;
        } else {
            sub.startTime = block.timestamp;
            newExpiryTime = block.timestamp + 30 days;
            sub.active = true;
            if (!hasEverSubscribed(msg.sender)) {
                totalSubscribers++;
            }
        }
        
        sub.expiryTime = newExpiryTime;
        
        emit SubscriptionRenewed(msg.sender, newExpiryTime, msg.value);
    }
    
    /**
     * @dev Subscribe for multiple months at once
     * @param months The number of months to subscribe for
     */
    function subscribeMultipleMonths(uint256 months) external payable {
        require(months > 0, "Must subscribe for at least 1 month");
        require(msg.value == monthlyFee * months, "Incorrect subscription fee");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        uint256 startTime;
        uint256 expiryTime;
        
        if (isSubscriptionActive(msg.sender)) {
            // Extend from current expiry
            startTime = sub.startTime;
            expiryTime = sub.expiryTime + (months * 30 days);
        } else {
            // New subscription
            startTime = block.timestamp;
            expiryTime = startTime + (months * 30 days);
            sub.active = true;
            if (!hasEverSubscribed(msg.sender)) {
                totalSubscribers++;
            }
        }
        
        sub.startTime = startTime;
        sub.expiryTime = expiryTime;
        
        emit SubscriptionRenewed(msg.sender, expiryTime, msg.value);
    }
    
    /**
     * @dev Cancel subscription (marks as inactive but doesn't refund)
     */
    function cancelSubscription() external hasActiveSubscription {
        subscriptions[msg.sender].active = false;
        
        emit SubscriptionCancelled(msg.sender);
    }
    
    /**
     * @dev Check if a user has an active subscription
     * @param user The address to check
     * @return True if the user has an active subscription, false otherwise
     */
    function isSubscriptionActive(address user) public view returns (bool) {
        Subscription memory sub = subscriptions[user];
        return sub.active && block.timestamp < sub.expiryTime;
    }
    
    /**
     * @dev Check if a user has ever subscribed
     * @param user The address to check
     * @return True if the user has ever subscribed, false otherwise
     */
    function hasEverSubscribed(address user) public view returns (bool) {
        return subscriptions[user].startTime > 0;
    }
    
    /**
     * @dev Get subscription details for a user
     * @param user The address to check
     * @return startTime The subscription start time
     * @return expiryTime The subscription expiry time
     * @return active Whether the subscription is active
     * @return isActive Current active status (considering time)
     */
    function getSubscriptionDetails(address user) external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool active,
        bool isActive
    ) {
        Subscription memory sub = subscriptions[user];
        return (
            sub.startTime,
            sub.expiryTime,
            sub.active,
            isSubscriptionActive(user)
        );
    }
    
    /**
     * @dev Get remaining time on subscription
     * @param user The address to check
     * @return The remaining time in seconds, or 0 if no active subscription
     */
    function getRemainingTime(address user) external view returns (uint256) {
        if (!isSubscriptionActive(user)) {
            return 0;
        }
        return subscriptions[user].expiryTime - block.timestamp;
    }
    
    /**
     * @dev Update the monthly subscription fee (only owner)
     * @param newFee The new monthly fee in wei
     */
    function setMonthlyFee(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Fee must be greater than 0");
        
        uint256 oldFee = monthlyFee;
        monthlyFee = newFee;
        
        emit MonthlyFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev Withdraw collected fees (only owner)
     * @param amount The amount to withdraw in wei
     */
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Withdraw all collected fees (only owner)
     */
    function withdrawAllFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Check if caller has active subscription
     * @return True if caller has an active subscription
     */
    function isMySubscriptionActive() external view returns (bool) {
        return isSubscriptionActive(msg.sender);
    }
}
