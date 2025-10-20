// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionSystem
 * @dev A basic subscription system where users pay ETH for monthly access
 */
contract SubscriptionSystem {
    address public owner;
    uint256 public monthlyPrice;
    
    struct Subscription {
        uint256 startTime;
        uint256 expiryTime;
        bool isActive;
    }
    
    // Mapping from user address to their subscription
    mapping(address => Subscription) public subscriptions;
    
    // Events
    event SubscriptionPurchased(address indexed user, uint256 startTime, uint256 expiryTime);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime);
    event SubscriptionCancelled(address indexed user);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the subscription system
     * @param _monthlyPrice The monthly subscription price in wei
     */
    constructor(uint256 _monthlyPrice) {
        require(_monthlyPrice > 0, "Price must be greater than 0");
        owner = msg.sender;
        monthlyPrice = _monthlyPrice;
    }
    
    /**
     * @dev Allows users to purchase a new subscription
     */
    function subscribe() external payable {
        require(msg.value == monthlyPrice, "Incorrect payment amount");
        require(!subscriptions[msg.sender].isActive || block.timestamp > subscriptions[msg.sender].expiryTime, 
                "Active subscription already exists");
        
        uint256 startTime = block.timestamp;
        uint256 expiryTime = startTime + 30 days;
        
        subscriptions[msg.sender] = Subscription({
            startTime: startTime,
            expiryTime: expiryTime,
            isActive: true
        });
        
        emit SubscriptionPurchased(msg.sender, startTime, expiryTime);
    }
    
    /**
     * @dev Allows users to renew their subscription
     */
    function renewSubscription() external payable {
        require(msg.value == monthlyPrice, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        // If subscription is still active, extend from expiry time, otherwise from now
        uint256 newExpiryTime;
        if (sub.isActive && block.timestamp < sub.expiryTime) {
            newExpiryTime = sub.expiryTime + 30 days;
        } else {
            sub.startTime = block.timestamp;
            newExpiryTime = block.timestamp + 30 days;
            sub.isActive = true;
        }
        
        sub.expiryTime = newExpiryTime;
        
        emit SubscriptionRenewed(msg.sender, newExpiryTime);
    }
    
    /**
     * @dev Allows users to cancel their subscription (no refund)
     */
    function cancelSubscription() external {
        require(subscriptions[msg.sender].isActive, "No active subscription");
        
        subscriptions[msg.sender].isActive = false;
        
        emit SubscriptionCancelled(msg.sender);
    }
    
    /**
     * @dev Checks if a user has an active subscription
     * @param _user The address of the user
     * @return True if the user has an active subscription, false otherwise
     */
    function isSubscribed(address _user) public view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        return sub.isActive && block.timestamp < sub.expiryTime;
    }
    
    /**
     * @dev Checks if the caller has an active subscription
     * @return True if the caller has an active subscription, false otherwise
     */
    function isMySubscriptionActive() external view returns (bool) {
        return isSubscribed(msg.sender);
    }
    
    /**
     * @dev Returns the subscription details for a user
     * @param _user The address of the user
     * @return startTime When the subscription started
     * @return expiryTime When the subscription expires
     * @return isActive Whether the subscription is active
     * @return isValid Whether the subscription is currently valid (active and not expired)
     */
    function getSubscriptionDetails(address _user) external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool isActive,
        bool isValid
    ) {
        Subscription memory sub = subscriptions[_user];
        bool valid = sub.isActive && block.timestamp < sub.expiryTime;
        
        return (
            sub.startTime,
            sub.expiryTime,
            sub.isActive,
            valid
        );
    }
    
    /**
     * @dev Returns the time remaining on a user's subscription
     * @param _user The address of the user
     * @return Time remaining in seconds, or 0 if expired or no subscription
     */
    function getTimeRemaining(address _user) external view returns (uint256) {
        Subscription memory sub = subscriptions[_user];
        
        if (!sub.isActive || block.timestamp >= sub.expiryTime) {
            return 0;
        }
        
        return sub.expiryTime - block.timestamp;
    }
    
    /**
     * @dev Allows the owner to update the monthly subscription price
     * @param _newPrice The new monthly price in wei
     */
    function updatePrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price must be greater than 0");
        
        uint256 oldPrice = monthlyPrice;
        monthlyPrice = _newPrice;
        
        emit PriceUpdated(oldPrice, _newPrice);
    }
    
    /**
     * @dev Allows the owner to withdraw collected funds
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    /**
     * @dev Allows the owner to withdraw a specific amount
     * @param _amount The amount to withdraw in wei
     */
    function withdrawAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, _amount);
    }
    
    /**
     * @dev Returns the contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
