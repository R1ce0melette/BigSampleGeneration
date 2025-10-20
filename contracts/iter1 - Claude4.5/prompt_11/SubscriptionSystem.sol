// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionSystem
 * @dev A basic subscription system where users pay ETH for monthly access
 */
contract SubscriptionSystem {
    address public owner;
    uint256 public subscriptionPrice;
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    
    struct Subscription {
        uint256 startTime;
        uint256 expiryTime;
        bool isActive;
    }
    
    mapping(address => Subscription) public subscriptions;
    address[] private subscribers;
    
    uint256 public totalRevenue;
    uint256 public activeSubscriberCount;
    
    event Subscribed(address indexed user, uint256 startTime, uint256 expiryTime);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime);
    event SubscriptionExpired(address indexed user);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event Withdrawal(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyActiveSubscriber() {
        require(isSubscriptionActive(msg.sender), "No active subscription");
        _;
    }
    
    /**
     * @dev Constructor to set initial subscription price
     * @param _subscriptionPrice Initial monthly subscription price in wei
     */
    constructor(uint256 _subscriptionPrice) {
        require(_subscriptionPrice > 0, "Price must be greater than 0");
        owner = msg.sender;
        subscriptionPrice = _subscriptionPrice;
    }
    
    /**
     * @dev Subscribe to the service
     */
    function subscribe() external payable {
        require(msg.value == subscriptionPrice, "Incorrect payment amount");
        
        Subscription storage userSub = subscriptions[msg.sender];
        
        uint256 startTime;
        uint256 expiryTime;
        
        // If user has an active subscription, extend it
        if (userSub.isActive && block.timestamp < userSub.expiryTime) {
            startTime = userSub.startTime;
            expiryTime = userSub.expiryTime + SUBSCRIPTION_DURATION;
            
            userSub.expiryTime = expiryTime;
            
            emit SubscriptionRenewed(msg.sender, expiryTime);
        } else {
            // New subscription or resubscription after expiry
            startTime = block.timestamp;
            expiryTime = block.timestamp + SUBSCRIPTION_DURATION;
            
            if (!userSub.isActive) {
                subscribers.push(msg.sender);
                activeSubscriberCount++;
            } else {
                activeSubscriberCount++;
            }
            
            userSub.startTime = startTime;
            userSub.expiryTime = expiryTime;
            userSub.isActive = true;
            
            emit Subscribed(msg.sender, startTime, expiryTime);
        }
        
        totalRevenue += msg.value;
    }
    
    /**
     * @dev Renew an existing subscription
     */
    function renew() external payable {
        require(msg.value == subscriptionPrice, "Incorrect payment amount");
        
        Subscription storage userSub = subscriptions[msg.sender];
        require(userSub.startTime > 0, "No subscription found");
        
        // Extend from current expiry or from now if expired
        if (block.timestamp < userSub.expiryTime) {
            userSub.expiryTime += SUBSCRIPTION_DURATION;
        } else {
            userSub.expiryTime = block.timestamp + SUBSCRIPTION_DURATION;
            if (!userSub.isActive) {
                userSub.isActive = true;
                activeSubscriberCount++;
            }
        }
        
        if (!userSub.isActive) {
            userSub.isActive = true;
        }
        
        totalRevenue += msg.value;
        
        emit SubscriptionRenewed(msg.sender, userSub.expiryTime);
    }
    
    /**
     * @dev Check if a user's subscription is active
     * @param user The address to check
     * @return Whether the subscription is active
     */
    function isSubscriptionActive(address user) public view returns (bool) {
        Subscription memory userSub = subscriptions[user];
        return userSub.isActive && block.timestamp < userSub.expiryTime;
    }
    
    /**
     * @dev Get time remaining on subscription
     * @param user The address to check
     * @return Time remaining in seconds (0 if expired)
     */
    function getTimeRemaining(address user) external view returns (uint256) {
        Subscription memory userSub = subscriptions[user];
        
        if (!userSub.isActive || block.timestamp >= userSub.expiryTime) {
            return 0;
        }
        
        return userSub.expiryTime - block.timestamp;
    }
    
    /**
     * @dev Get subscription details for a user
     * @param user The address to query
     * @return startTime When the subscription started
     * @return expiryTime When the subscription expires
     * @return isActive Whether the subscription is active
     * @return timeRemaining Time remaining in seconds
     */
    function getSubscriptionDetails(address user) external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool isActive,
        uint256 timeRemaining
    ) {
        Subscription memory userSub = subscriptions[user];
        
        isActive = userSub.isActive && block.timestamp < userSub.expiryTime;
        
        if (isActive) {
            timeRemaining = userSub.expiryTime - block.timestamp;
        } else {
            timeRemaining = 0;
        }
        
        return (
            userSub.startTime,
            userSub.expiryTime,
            isActive,
            timeRemaining
        );
    }
    
    /**
     * @dev Update subscription price (only owner)
     * @param newPrice The new subscription price in wei
     */
    function updatePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        
        uint256 oldPrice = subscriptionPrice;
        subscriptionPrice = newPrice;
        
        emit PriceUpdated(oldPrice, newPrice);
    }
    
    /**
     * @dev Withdraw contract balance (only owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, balance);
    }
    
    /**
     * @dev Withdraw specific amount (only owner)
     * @param amount The amount to withdraw
     */
    function withdrawAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, amount);
    }
    
    /**
     * @dev Get all subscribers
     * @return Array of subscriber addresses
     */
    function getAllSubscribers() external view returns (address[] memory) {
        return subscribers;
    }
    
    /**
     * @dev Get active subscribers
     * @return Array of active subscriber addresses
     */
    function getActiveSubscribers() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count active subscribers
        for (uint256 i = 0; i < subscribers.length; i++) {
            if (isSubscriptionActive(subscribers[i])) {
                count++;
            }
        }
        
        // Create array and populate
        address[] memory activeList = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < subscribers.length; i++) {
            if (isSubscriptionActive(subscribers[i])) {
                activeList[index] = subscribers[i];
                index++;
            }
        }
        
        return activeList;
    }
    
    /**
     * @dev Get contract statistics
     * @return _subscriptionPrice Current subscription price
     * @return _totalRevenue Total revenue collected
     * @return _activeSubscriberCount Number of active subscribers
     * @return _totalSubscribers Total number of subscribers (ever)
     * @return _contractBalance Current contract balance
     */
    function getStats() external view returns (
        uint256 _subscriptionPrice,
        uint256 _totalRevenue,
        uint256 _activeSubscriberCount,
        uint256 _totalSubscribers,
        uint256 _contractBalance
    ) {
        // Count currently active subscribers
        uint256 currentlyActive = 0;
        for (uint256 i = 0; i < subscribers.length; i++) {
            if (isSubscriptionActive(subscribers[i])) {
                currentlyActive++;
            }
        }
        
        return (
            subscriptionPrice,
            totalRevenue,
            currentlyActive,
            subscribers.length,
            address(this).balance
        );
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
