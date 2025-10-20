// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RecurringPaymentSystem
 * @dev A contract for a recurring payment system where users can authorize weekly or monthly payments to another address
 */
contract RecurringPaymentSystem {
    enum PaymentInterval {
        WEEKLY,
        MONTHLY
    }
    
    enum SubscriptionStatus {
        ACTIVE,
        PAUSED,
        CANCELLED
    }
    
    struct Subscription {
        uint256 id;
        address payer;
        address payable recipient;
        uint256 amount;
        PaymentInterval interval;
        uint256 startTime;
        uint256 nextPaymentDue;
        uint256 totalPaid;
        uint256 paymentCount;
        SubscriptionStatus status;
    }
    
    uint256 private subscriptionCounter;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) private payerSubscriptions;
    mapping(address => uint256[]) private recipientSubscriptions;
    
    uint256 public constant WEEKLY_INTERVAL = 7 days;
    uint256 public constant MONTHLY_INTERVAL = 30 days;
    
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address indexed payer,
        address indexed recipient,
        uint256 amount,
        PaymentInterval interval
    );
    
    event PaymentProcessed(
        uint256 indexed subscriptionId,
        address indexed payer,
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );
    
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionUpdated(uint256 indexed subscriptionId, uint256 newAmount);
    
    /**
     * @dev Create a recurring payment subscription
     * @param recipient The address to receive payments
     * @param amount The amount per payment
     * @param interval The payment interval (weekly or monthly)
     * @return subscriptionId The ID of the created subscription
     */
    function createSubscription(
        address payable recipient,
        uint256 amount,
        PaymentInterval interval
    ) external payable returns (uint256) {
        require(recipient != address(0), "Invalid recipient");
        require(recipient != msg.sender, "Cannot subscribe to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= amount, "Insufficient initial payment");
        
        subscriptionCounter++;
        uint256 subscriptionId = subscriptionCounter;
        
        uint256 intervalDuration = _getIntervalDuration(interval);
        uint256 nextPaymentDue = block.timestamp + intervalDuration;
        
        subscriptions[subscriptionId] = Subscription({
            id: subscriptionId,
            payer: msg.sender,
            recipient: recipient,
            amount: amount,
            interval: interval,
            startTime: block.timestamp,
            nextPaymentDue: nextPaymentDue,
            totalPaid: amount,
            paymentCount: 1,
            status: SubscriptionStatus.ACTIVE
        });
        
        payerSubscriptions[msg.sender].push(subscriptionId);
        recipientSubscriptions[recipient].push(subscriptionId);
        
        // Process initial payment
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Initial payment failed");
        
        // Refund excess
        if (msg.value > amount) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - amount}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit SubscriptionCreated(subscriptionId, msg.sender, recipient, amount, interval);
        emit PaymentProcessed(subscriptionId, msg.sender, recipient, amount, block.timestamp);
        
        return subscriptionId;
    }
    
    /**
     * @dev Process a payment for a subscription
     * @param subscriptionId The ID of the subscription
     */
    function processPayment(uint256 subscriptionId) external payable {
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.id != 0, "Subscription does not exist");
        require(msg.sender == sub.payer, "Only payer can process payment");
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription not active");
        require(block.timestamp >= sub.nextPaymentDue, "Payment not yet due");
        require(msg.value >= sub.amount, "Insufficient payment amount");
        
        // Update subscription
        uint256 intervalDuration = _getIntervalDuration(sub.interval);
        sub.nextPaymentDue = block.timestamp + intervalDuration;
        sub.totalPaid += sub.amount;
        sub.paymentCount++;
        
        // Transfer payment
        (bool success, ) = sub.recipient.call{value: sub.amount}("");
        require(success, "Payment transfer failed");
        
        // Refund excess
        if (msg.value > sub.amount) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - sub.amount}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit PaymentProcessed(subscriptionId, sub.payer, sub.recipient, sub.amount, block.timestamp);
    }
    
    /**
     * @dev Pause a subscription
     * @param subscriptionId The ID of the subscription
     */
    function pauseSubscription(uint256 subscriptionId) external {
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.id != 0, "Subscription does not exist");
        require(msg.sender == sub.payer, "Only payer can pause");
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription not active");
        
        sub.status = SubscriptionStatus.PAUSED;
        
        emit SubscriptionPaused(subscriptionId);
    }
    
    /**
     * @dev Resume a paused subscription
     * @param subscriptionId The ID of the subscription
     */
    function resumeSubscription(uint256 subscriptionId) external {
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.id != 0, "Subscription does not exist");
        require(msg.sender == sub.payer, "Only payer can resume");
        require(sub.status == SubscriptionStatus.PAUSED, "Subscription not paused");
        
        // Reset next payment due from current time
        uint256 intervalDuration = _getIntervalDuration(sub.interval);
        sub.nextPaymentDue = block.timestamp + intervalDuration;
        sub.status = SubscriptionStatus.ACTIVE;
        
        emit SubscriptionResumed(subscriptionId);
    }
    
    /**
     * @dev Cancel a subscription
     * @param subscriptionId The ID of the subscription
     */
    function cancelSubscription(uint256 subscriptionId) external {
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.id != 0, "Subscription does not exist");
        require(
            msg.sender == sub.payer || msg.sender == sub.recipient,
            "Only payer or recipient can cancel"
        );
        require(sub.status != SubscriptionStatus.CANCELLED, "Already cancelled");
        
        sub.status = SubscriptionStatus.CANCELLED;
        
        emit SubscriptionCancelled(subscriptionId);
    }
    
    /**
     * @dev Update subscription amount
     * @param subscriptionId The ID of the subscription
     * @param newAmount The new payment amount
     */
    function updateSubscriptionAmount(uint256 subscriptionId, uint256 newAmount) external {
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.id != 0, "Subscription does not exist");
        require(msg.sender == sub.payer, "Only payer can update amount");
        require(newAmount > 0, "Amount must be greater than 0");
        require(sub.status != SubscriptionStatus.CANCELLED, "Subscription cancelled");
        
        sub.amount = newAmount;
        
        emit SubscriptionUpdated(subscriptionId, newAmount);
    }
    
    /**
     * @dev Get subscription details
     * @param subscriptionId The ID of the subscription
     * @return id Subscription ID
     * @return payer Payer address
     * @return recipient Recipient address
     * @return amount Payment amount
     * @return interval Payment interval
     * @return startTime Start timestamp
     * @return nextPaymentDue Next payment due timestamp
     * @return totalPaid Total amount paid
     * @return paymentCount Number of payments made
     * @return status Current status
     */
    function getSubscriptionDetails(uint256 subscriptionId) external view returns (
        uint256 id,
        address payer,
        address recipient,
        uint256 amount,
        PaymentInterval interval,
        uint256 startTime,
        uint256 nextPaymentDue,
        uint256 totalPaid,
        uint256 paymentCount,
        SubscriptionStatus status
    ) {
        Subscription memory sub = subscriptions[subscriptionId];
        require(sub.id != 0, "Subscription does not exist");
        
        return (
            sub.id,
            sub.payer,
            sub.recipient,
            sub.amount,
            sub.interval,
            sub.startTime,
            sub.nextPaymentDue,
            sub.totalPaid,
            sub.paymentCount,
            sub.status
        );
    }
    
    /**
     * @dev Get subscriptions created by a payer
     * @param payer The payer's address
     * @return Array of subscription IDs
     */
    function getSubscriptionsByPayer(address payer) external view returns (uint256[] memory) {
        return payerSubscriptions[payer];
    }
    
    /**
     * @dev Get subscriptions for a recipient
     * @param recipient The recipient's address
     * @return Array of subscription IDs
     */
    function getSubscriptionsByRecipient(address recipient) external view returns (uint256[] memory) {
        return recipientSubscriptions[recipient];
    }
    
    /**
     * @dev Check if a payment is due for a subscription
     * @param subscriptionId The ID of the subscription
     * @return Whether payment is due
     */
    function isPaymentDue(uint256 subscriptionId) external view returns (bool) {
        Subscription memory sub = subscriptions[subscriptionId];
        
        if (sub.id == 0 || sub.status != SubscriptionStatus.ACTIVE) {
            return false;
        }
        
        return block.timestamp >= sub.nextPaymentDue;
    }
    
    /**
     * @dev Get time until next payment
     * @param subscriptionId The ID of the subscription
     * @return Time in seconds (0 if payment is due or overdue)
     */
    function getTimeUntilNextPayment(uint256 subscriptionId) external view returns (uint256) {
        Subscription memory sub = subscriptions[subscriptionId];
        
        require(sub.id != 0, "Subscription does not exist");
        
        if (block.timestamp >= sub.nextPaymentDue) {
            return 0;
        }
        
        return sub.nextPaymentDue - block.timestamp;
    }
    
    /**
     * @dev Get active subscriptions for a payer
     * @param payer The payer's address
     * @return Array of active subscription IDs
     */
    function getActiveSubscriptionsByPayer(address payer) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count active subscriptions
        for (uint256 i = 0; i < payerSubscriptions[payer].length; i++) {
            uint256 subId = payerSubscriptions[payer][i];
            if (subscriptions[subId].status == SubscriptionStatus.ACTIVE) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeSubs = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < payerSubscriptions[payer].length; i++) {
            uint256 subId = payerSubscriptions[payer][i];
            if (subscriptions[subId].status == SubscriptionStatus.ACTIVE) {
                activeSubs[index] = subId;
                index++;
            }
        }
        
        return activeSubs;
    }
    
    /**
     * @dev Get total number of subscriptions
     * @return The total count
     */
    function getTotalSubscriptions() external view returns (uint256) {
        return subscriptionCounter;
    }
    
    /**
     * @dev Internal function to get interval duration
     * @param interval The payment interval
     * @return Duration in seconds
     */
    function _getIntervalDuration(PaymentInterval interval) private pure returns (uint256) {
        if (interval == PaymentInterval.WEEKLY) {
            return WEEKLY_INTERVAL;
        } else {
            return MONTHLY_INTERVAL;
        }
    }
}
