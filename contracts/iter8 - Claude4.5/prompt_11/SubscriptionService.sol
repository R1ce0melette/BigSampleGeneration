// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SubscriptionService
 * @dev Basic subscription system where users pay ETH for monthly access
 */
contract SubscriptionService {
    // Subscription structure
    struct Subscription {
        address user;
        uint256 startTime;
        uint256 expiryTime;
        uint256 totalPaid;
        uint256 renewalCount;
        bool isActive;
    }

    // Payment record
    struct Payment {
        address user;
        uint256 amount;
        uint256 timestamp;
        uint256 monthsPaid;
    }

    // State variables
    address public owner;
    uint256 public monthlyPrice;
    uint256 public constant MONTH_DURATION = 30 days;
    
    mapping(address => Subscription) private subscriptions;
    mapping(address => Payment[]) private userPayments;
    Payment[] private allPayments;
    
    address[] private subscribers;
    mapping(address => bool) private isSubscriber;

    // Events
    event Subscribed(address indexed user, uint256 expiryTime, uint256 amount, uint256 timestamp);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime, uint256 amount, uint256 timestamp);
    event SubscriptionCancelled(address indexed user, uint256 timestamp);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier hasActiveSubscription() {
        require(isSubscriptionActive(msg.sender), "No active subscription");
        _;
    }

    constructor(uint256 _monthlyPrice) {
        require(_monthlyPrice > 0, "Price must be greater than 0");
        owner = msg.sender;
        monthlyPrice = _monthlyPrice;
    }

    /**
     * @dev Subscribe for monthly access
     * @param months Number of months to subscribe
     */
    function subscribe(uint256 months) public payable {
        require(months > 0, "Must subscribe for at least 1 month");
        require(months <= 12, "Cannot subscribe for more than 12 months");
        uint256 totalCost = monthlyPrice * months;
        require(msg.value == totalCost, "Incorrect payment amount");

        Subscription storage sub = subscriptions[msg.sender];
        
        if (!isSubscriber[msg.sender]) {
            subscribers.push(msg.sender);
            isSubscriber[msg.sender] = true;
        }

        uint256 startTime;
        uint256 expiryTime;

        if (sub.isActive && block.timestamp < sub.expiryTime) {
            // Extend existing subscription
            startTime = sub.startTime;
            expiryTime = sub.expiryTime + (months * MONTH_DURATION);
            sub.renewalCount++;
        } else {
            // New or expired subscription
            startTime = block.timestamp;
            expiryTime = block.timestamp + (months * MONTH_DURATION);
            sub.startTime = startTime;
            sub.renewalCount = 0;
        }

        sub.user = msg.sender;
        sub.expiryTime = expiryTime;
        sub.totalPaid += msg.value;
        sub.isActive = true;

        // Record payment
        Payment memory payment = Payment({
            user: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            monthsPaid: months
        });

        userPayments[msg.sender].push(payment);
        allPayments.push(payment);

        emit Subscribed(msg.sender, expiryTime, msg.value, block.timestamp);
    }

    /**
     * @dev Renew subscription for additional months
     * @param months Number of months to renew
     */
    function renewSubscription(uint256 months) public payable {
        subscribe(months);
    }

    /**
     * @dev Cancel subscription (marks as inactive but doesn't refund)
     */
    function cancelSubscription() public hasActiveSubscription {
        subscriptions[msg.sender].isActive = false;
        emit SubscriptionCancelled(msg.sender, block.timestamp);
    }

    /**
     * @dev Check if a user has an active subscription
     * @param user User address
     * @return true if subscription is active
     */
    function isSubscriptionActive(address user) public view returns (bool) {
        Subscription memory sub = subscriptions[user];
        return sub.isActive && block.timestamp < sub.expiryTime;
    }

    /**
     * @dev Check if caller has an active subscription
     * @return true if subscription is active
     */
    function isMySubscriptionActive() public view returns (bool) {
        return isSubscriptionActive(msg.sender);
    }

    /**
     * @dev Get subscription details for a user
     * @param user User address
     * @return Subscription details
     */
    function getSubscription(address user) public view returns (Subscription memory) {
        return subscriptions[user];
    }

    /**
     * @dev Get caller's subscription details
     * @return Subscription details
     */
    function getMySubscription() public view returns (Subscription memory) {
        return subscriptions[msg.sender];
    }

    /**
     * @dev Get time remaining on subscription
     * @param user User address
     * @return Seconds remaining (0 if expired)
     */
    function getTimeRemaining(address user) public view returns (uint256) {
        Subscription memory sub = subscriptions[user];
        if (!sub.isActive || block.timestamp >= sub.expiryTime) {
            return 0;
        }
        return sub.expiryTime - block.timestamp;
    }

    /**
     * @dev Get caller's time remaining
     * @return Seconds remaining (0 if expired)
     */
    function getMyTimeRemaining() public view returns (uint256) {
        return getTimeRemaining(msg.sender);
    }

    /**
     * @dev Get payment history for a user
     * @param user User address
     * @return Array of payments
     */
    function getUserPayments(address user) public view returns (Payment[] memory) {
        return userPayments[user];
    }

    /**
     * @dev Get caller's payment history
     * @return Array of payments
     */
    function getMyPayments() public view returns (Payment[] memory) {
        return userPayments[msg.sender];
    }

    /**
     * @dev Get all payments
     * @return Array of all payments
     */
    function getAllPayments() public view returns (Payment[] memory) {
        return allPayments;
    }

    /**
     * @dev Get all subscribers
     * @return Array of subscriber addresses
     */
    function getAllSubscribers() public view returns (address[] memory) {
        return subscribers;
    }

    /**
     * @dev Get active subscribers
     * @return Array of active subscriber addresses
     */
    function getActiveSubscribers() public view returns (address[] memory) {
        uint256 activeCount = 0;

        for (uint256 i = 0; i < subscribers.length; i++) {
            if (isSubscriptionActive(subscribers[i])) {
                activeCount++;
            }
        }

        address[] memory activeSubscribers = new address[](activeCount);
        uint256 index = 0;

        for (uint256 i = 0; i < subscribers.length; i++) {
            if (isSubscriptionActive(subscribers[i])) {
                activeSubscribers[index] = subscribers[i];
                index++;
            }
        }

        return activeSubscribers;
    }

    /**
     * @dev Get total number of subscribers
     * @return Total subscriber count
     */
    function getTotalSubscribers() public view returns (uint256) {
        return subscribers.length;
    }

    /**
     * @dev Get number of active subscribers
     * @return Active subscriber count
     */
    function getActiveSubscriberCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < subscribers.length; i++) {
            if (isSubscriptionActive(subscribers[i])) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Update monthly price
     * @param newPrice New monthly price
     */
    function setMonthlyPrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        
        uint256 oldPrice = monthlyPrice;
        monthlyPrice = newPrice;

        emit PriceUpdated(oldPrice, newPrice);
    }

    /**
     * @dev Withdraw collected funds
     * @param amount Amount to withdraw
     */
    function withdrawFunds(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        payable(owner).transfer(amount);

        emit FundsWithdrawn(owner, amount);
    }

    /**
     * @dev Withdraw all collected funds
     */
    function withdrawAllFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);

        emit FundsWithdrawn(owner, balance);
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Calculate cost for multiple months
     * @param months Number of months
     * @return Total cost
     */
    function calculateCost(uint256 months) public view returns (uint256) {
        return monthlyPrice * months;
    }

    /**
     * @dev Get total revenue
     * @return Total revenue collected
     */
    function getTotalRevenue() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < allPayments.length; i++) {
            total += allPayments[i].amount;
        }
        return total;
    }

    /**
     * @dev Get subscriber statistics
     * @param user User address
     * @return totalPaid Total amount paid
     * @return renewalCount Number of renewals
     * @return isActive Active status
     * @return timeRemaining Time remaining in seconds
     */
    function getSubscriberStats(address user) 
        public 
        view 
        returns (
            uint256 totalPaid,
            uint256 renewalCount,
            bool isActive,
            uint256 timeRemaining
        ) 
    {
        Subscription memory sub = subscriptions[user];
        return (
            sub.totalPaid,
            sub.renewalCount,
            isSubscriptionActive(user),
            getTimeRemaining(user)
        );
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
