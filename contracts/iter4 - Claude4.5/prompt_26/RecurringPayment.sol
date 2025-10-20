// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RecurringPayment
 * @dev A contract for recurring payment system where users can authorize weekly or monthly payments to another address
 */
contract RecurringPayment {
    enum PaymentInterval { WEEKLY, MONTHLY }
    enum SubscriptionStatus { ACTIVE, PAUSED, CANCELLED }
    
    struct Subscription {
        uint256 id;
        address payer;
        address payee;
        uint256 amount;
        PaymentInterval interval;
        uint256 startTime;
        uint256 lastPaymentTime;
        uint256 nextPaymentTime;
        uint256 totalPayments;
        SubscriptionStatus status;
    }
    
    uint256 public subscriptionCount;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public payerSubscriptions;
    mapping(address => uint256[]) public payeeSubscriptions;
    
    // User balances for pre-funded payments
    mapping(address => uint256) public balances;
    
    // Events
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, PaymentInterval interval);
    event PaymentProcessed(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, uint256 timestamp);
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionUpdated(uint256 indexed subscriptionId, uint256 newAmount);
    event BalanceDeposited(address indexed user, uint256 amount);
    event BalanceWithdrawn(address indexed user, uint256 amount);
    
    /**
     * @dev Creates a new recurring payment subscription
     * @param _payee The address to receive payments
     * @param _amount The payment amount
     * @param _interval The payment interval (0 = WEEKLY, 1 = MONTHLY)
     */
    function createSubscription(
        address _payee,
        uint256 _amount,
        PaymentInterval _interval
    ) external {
        require(_payee != address(0), "Invalid payee address");
        require(_payee != msg.sender, "Cannot subscribe to self");
        require(_amount > 0, "Amount must be greater than 0");
        
        subscriptionCount++;
        
        uint256 intervalSeconds = _interval == PaymentInterval.WEEKLY ? 7 days : 30 days;
        uint256 nextPayment = block.timestamp + intervalSeconds;
        
        subscriptions[subscriptionCount] = Subscription({
            id: subscriptionCount,
            payer: msg.sender,
            payee: _payee,
            amount: _amount,
            interval: _interval,
            startTime: block.timestamp,
            lastPaymentTime: 0,
            nextPaymentTime: nextPayment,
            totalPayments: 0,
            status: SubscriptionStatus.ACTIVE
        });
        
        payerSubscriptions[msg.sender].push(subscriptionCount);
        payeeSubscriptions[_payee].push(subscriptionCount);
        
        emit SubscriptionCreated(subscriptionCount, msg.sender, _payee, _amount, _interval);
    }
    
    /**
     * @dev Deposits funds to the user's balance for recurring payments
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        
        emit BalanceDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Processes a payment for a subscription
     * @param _subscriptionId The ID of the subscription
     */
    function processPayment(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        require(block.timestamp >= sub.nextPaymentTime, "Payment not due yet");
        require(balances[sub.payer] >= sub.amount, "Insufficient balance");
        
        // Process payment
        balances[sub.payer] -= sub.amount;
        
        // Transfer to payee
        (bool success, ) = sub.payee.call{value: sub.amount}("");
        require(success, "Payment transfer failed");
        
        // Update subscription
        sub.lastPaymentTime = block.timestamp;
        sub.totalPayments++;
        
        uint256 intervalSeconds = sub.interval == PaymentInterval.WEEKLY ? 7 days : 30 days;
        sub.nextPaymentTime = block.timestamp + intervalSeconds;
        
        emit PaymentProcessed(_subscriptionId, sub.payer, sub.payee, sub.amount, block.timestamp);
    }
    
    /**
     * @dev Pauses a subscription
     * @param _subscriptionId The ID of the subscription
     */
    function pauseSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can pause subscription");
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        
        sub.status = SubscriptionStatus.PAUSED;
        
        emit SubscriptionPaused(_subscriptionId);
    }
    
    /**
     * @dev Resumes a paused subscription
     * @param _subscriptionId The ID of the subscription
     */
    function resumeSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can resume subscription");
        require(sub.status == SubscriptionStatus.PAUSED, "Subscription is not paused");
        
        sub.status = SubscriptionStatus.ACTIVE;
        
        // Reset next payment time
        uint256 intervalSeconds = sub.interval == PaymentInterval.WEEKLY ? 7 days : 30 days;
        sub.nextPaymentTime = block.timestamp + intervalSeconds;
        
        emit SubscriptionResumed(_subscriptionId);
    }
    
    /**
     * @dev Cancels a subscription
     * @param _subscriptionId The ID of the subscription
     */
    function cancelSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can cancel subscription");
        require(sub.status != SubscriptionStatus.CANCELLED, "Subscription already cancelled");
        
        sub.status = SubscriptionStatus.CANCELLED;
        
        emit SubscriptionCancelled(_subscriptionId);
    }
    
    /**
     * @dev Updates the payment amount for a subscription
     * @param _subscriptionId The ID of the subscription
     * @param _newAmount The new payment amount
     */
    function updateSubscriptionAmount(uint256 _subscriptionId, uint256 _newAmount) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        require(_newAmount > 0, "Amount must be greater than 0");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can update subscription");
        require(sub.status != SubscriptionStatus.CANCELLED, "Subscription is cancelled");
        
        sub.amount = _newAmount;
        
        emit SubscriptionUpdated(_subscriptionId, _newAmount);
    }
    
    /**
     * @dev Withdraws balance
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit BalanceWithdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Returns the details of a subscription
     * @param _subscriptionId The ID of the subscription
     * @return id The subscription ID
     * @return payer The payer's address
     * @return payee The payee's address
     * @return amount The payment amount
     * @return interval The payment interval
     * @return nextPaymentTime When the next payment is due
     * @return totalPayments Total payments made
     * @return status The subscription status
     */
    function getSubscription(uint256 _subscriptionId) external view returns (
        uint256 id,
        address payer,
        address payee,
        uint256 amount,
        PaymentInterval interval,
        uint256 nextPaymentTime,
        uint256 totalPayments,
        SubscriptionStatus status
    ) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return (
            sub.id,
            sub.payer,
            sub.payee,
            sub.amount,
            sub.interval,
            sub.nextPaymentTime,
            sub.totalPayments,
            sub.status
        );
    }
    
    /**
     * @dev Returns all subscriptions where the caller is the payer
     * @return Array of subscription IDs
     */
    function getMyPayerSubscriptions() external view returns (uint256[] memory) {
        return payerSubscriptions[msg.sender];
    }
    
    /**
     * @dev Returns all subscriptions where the caller is the payee
     * @return Array of subscription IDs
     */
    function getMyPayeeSubscriptions() external view returns (uint256[] memory) {
        return payeeSubscriptions[msg.sender];
    }
    
    /**
     * @dev Returns active subscriptions for a payer
     * @param _payer The address of the payer
     * @return Array of subscription IDs
     */
    function getActiveSubscriptionsByPayer(address _payer) external view returns (uint256[] memory) {
        uint256[] memory allSubs = payerSubscriptions[_payer];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            if (subscriptions[allSubs[i]].status == SubscriptionStatus.ACTIVE) {
                activeCount++;
            }
        }
        
        uint256[] memory activeSubs = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            if (subscriptions[allSubs[i]].status == SubscriptionStatus.ACTIVE) {
                activeSubs[index] = allSubs[i];
                index++;
            }
        }
        
        return activeSubs;
    }
    
    /**
     * @dev Returns subscriptions that are due for payment
     * @param _payer The address of the payer
     * @return Array of subscription IDs
     */
    function getDueSubscriptions(address _payer) external view returns (uint256[] memory) {
        uint256[] memory allSubs = payerSubscriptions[_payer];
        uint256 dueCount = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            Subscription memory sub = subscriptions[allSubs[i]];
            if (sub.status == SubscriptionStatus.ACTIVE && 
                block.timestamp >= sub.nextPaymentTime &&
                balances[_payer] >= sub.amount) {
                dueCount++;
            }
        }
        
        uint256[] memory dueSubs = new uint256[](dueCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            Subscription memory sub = subscriptions[allSubs[i]];
            if (sub.status == SubscriptionStatus.ACTIVE && 
                block.timestamp >= sub.nextPaymentTime &&
                balances[_payer] >= sub.amount) {
                dueSubs[index] = allSubs[i];
                index++;
            }
        }
        
        return dueSubs;
    }
    
    /**
     * @dev Returns the caller's balance
     * @return The balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Returns the time until next payment
     * @param _subscriptionId The ID of the subscription
     * @return Time in seconds, or 0 if payment is due
     */
    function getTimeUntilNextPayment(uint256 _subscriptionId) external view returns (uint256) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        if (block.timestamp >= sub.nextPaymentTime) {
            return 0;
        }
        
        return sub.nextPaymentTime - block.timestamp;
    }
    
    /**
     * @dev Checks if a payment is due for a subscription
     * @param _subscriptionId The ID of the subscription
     * @return True if payment is due, false otherwise
     */
    function isPaymentDue(uint256 _subscriptionId) external view returns (bool) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return sub.status == SubscriptionStatus.ACTIVE && 
               block.timestamp >= sub.nextPaymentTime;
    }
    
    /**
     * @dev Returns the interval as a string
     * @param _subscriptionId The ID of the subscription
     * @return The interval as a string
     */
    function getIntervalString(uint256 _subscriptionId) external view returns (string memory) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        if (subscriptions[_subscriptionId].interval == PaymentInterval.WEEKLY) {
            return "WEEKLY";
        } else {
            return "MONTHLY";
        }
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit BalanceDeposited(msg.sender, msg.value);
    }
}
