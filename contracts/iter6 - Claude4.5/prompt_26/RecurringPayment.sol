// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RecurringPayment
 * @dev A contract for recurring payment system where users can authorize weekly or monthly payments to another address
 */
contract RecurringPayment {
    enum PaymentFrequency { WEEKLY, MONTHLY }
    enum SubscriptionStatus { ACTIVE, PAUSED, CANCELLED }
    
    struct Subscription {
        uint256 id;
        address payer;
        address payee;
        uint256 amount;
        PaymentFrequency frequency;
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
    
    uint256 public constant WEEK_DURATION = 7 days;
    uint256 public constant MONTH_DURATION = 30 days;
    
    // Events
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, PaymentFrequency frequency);
    event PaymentExecuted(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, uint256 timestamp);
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionFunded(uint256 indexed subscriptionId, address indexed funder, uint256 amount);
    
    /**
     * @dev Create a new recurring payment subscription
     * @param payee The address to receive payments
     * @param amount The payment amount
     * @param frequency The payment frequency (WEEKLY or MONTHLY)
     */
    function createSubscription(
        address payee,
        uint256 amount,
        PaymentFrequency frequency
    ) external payable {
        require(payee != address(0), "Invalid payee address");
        require(payee != msg.sender, "Cannot subscribe to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= amount, "Insufficient initial payment");
        
        subscriptionCount++;
        
        uint256 paymentInterval = frequency == PaymentFrequency.WEEKLY ? WEEK_DURATION : MONTH_DURATION;
        
        subscriptions[subscriptionCount] = Subscription({
            id: subscriptionCount,
            payer: msg.sender,
            payee: payee,
            amount: amount,
            frequency: frequency,
            startTime: block.timestamp,
            lastPaymentTime: block.timestamp,
            nextPaymentTime: block.timestamp + paymentInterval,
            totalPayments: 0,
            status: SubscriptionStatus.ACTIVE
        });
        
        payerSubscriptions[msg.sender].push(subscriptionCount);
        payeeSubscriptions[payee].push(subscriptionCount);
        
        // Execute first payment
        (bool success, ) = payee.call{value: amount}("");
        require(success, "Initial payment failed");
        
        subscriptions[subscriptionCount].totalPayments++;
        
        emit SubscriptionCreated(subscriptionCount, msg.sender, payee, amount, frequency);
        emit PaymentExecuted(subscriptionCount, msg.sender, payee, amount, block.timestamp);
    }
    
    /**
     * @dev Execute a payment for a subscription
     * @param subscriptionId The ID of the subscription
     */
    function executePayment(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        require(block.timestamp >= sub.nextPaymentTime, "Payment not due yet");
        require(address(this).balance >= sub.amount, "Insufficient contract balance");
        
        uint256 paymentInterval = sub.frequency == PaymentFrequency.WEEKLY ? WEEK_DURATION : MONTH_DURATION;
        
        sub.lastPaymentTime = block.timestamp;
        sub.nextPaymentTime = block.timestamp + paymentInterval;
        sub.totalPayments++;
        
        (bool success, ) = sub.payee.call{value: sub.amount}("");
        require(success, "Payment transfer failed");
        
        emit PaymentExecuted(subscriptionId, sub.payer, sub.payee, sub.amount, block.timestamp);
    }
    
    /**
     * @dev Fund a subscription with ETH
     * @param subscriptionId The ID of the subscription
     */
    function fundSubscription(uint256 subscriptionId) external payable {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        require(msg.value > 0, "Must send some ETH");
        
        Subscription storage sub = subscriptions[subscriptionId];
        require(msg.sender == sub.payer, "Only payer can fund subscription");
        
        emit SubscriptionFunded(subscriptionId, msg.sender, msg.value);
    }
    
    /**
     * @dev Pause a subscription
     * @param subscriptionId The ID of the subscription
     */
    function pauseSubscription(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can pause subscription");
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        
        sub.status = SubscriptionStatus.PAUSED;
        
        emit SubscriptionPaused(subscriptionId);
    }
    
    /**
     * @dev Resume a paused subscription
     * @param subscriptionId The ID of the subscription
     */
    function resumeSubscription(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can resume subscription");
        require(sub.status == SubscriptionStatus.PAUSED, "Subscription is not paused");
        
        // Reset next payment time from current time
        uint256 paymentInterval = sub.frequency == PaymentFrequency.WEEKLY ? WEEK_DURATION : MONTH_DURATION;
        sub.nextPaymentTime = block.timestamp + paymentInterval;
        sub.status = SubscriptionStatus.ACTIVE;
        
        emit SubscriptionResumed(subscriptionId);
    }
    
    /**
     * @dev Cancel a subscription
     * @param subscriptionId The ID of the subscription
     */
    function cancelSubscription(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can cancel subscription");
        require(sub.status != SubscriptionStatus.CANCELLED, "Subscription already cancelled");
        
        sub.status = SubscriptionStatus.CANCELLED;
        
        emit SubscriptionCancelled(subscriptionId);
    }
    
    /**
     * @dev Get subscription details
     * @param subscriptionId The ID of the subscription
     * @return id Subscription ID
     * @return payer Payer's address
     * @return payee Payee's address
     * @return amount Payment amount
     * @return frequency Payment frequency
     * @return startTime Start time
     * @return lastPaymentTime Last payment time
     * @return nextPaymentTime Next payment time
     * @return totalPayments Total payments made
     * @return status Subscription status
     */
    function getSubscription(uint256 subscriptionId) external view returns (
        uint256 id,
        address payer,
        address payee,
        uint256 amount,
        PaymentFrequency frequency,
        uint256 startTime,
        uint256 lastPaymentTime,
        uint256 nextPaymentTime,
        uint256 totalPayments,
        SubscriptionStatus status
    ) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription memory sub = subscriptions[subscriptionId];
        
        return (
            sub.id,
            sub.payer,
            sub.payee,
            sub.amount,
            sub.frequency,
            sub.startTime,
            sub.lastPaymentTime,
            sub.nextPaymentTime,
            sub.totalPayments,
            sub.status
        );
    }
    
    /**
     * @dev Get all subscriptions where caller is the payer
     * @return Array of subscription IDs
     */
    function getMyPayerSubscriptions() external view returns (uint256[] memory) {
        return payerSubscriptions[msg.sender];
    }
    
    /**
     * @dev Get all subscriptions where caller is the payee
     * @return Array of subscription IDs
     */
    function getMyPayeeSubscriptions() external view returns (uint256[] memory) {
        return payeeSubscriptions[msg.sender];
    }
    
    /**
     * @dev Get active subscriptions for a payer
     * @param payer The payer's address
     * @return Array of active subscription IDs
     */
    function getActiveSubscriptionsByPayer(address payer) external view returns (uint256[] memory) {
        uint256[] memory allSubs = payerSubscriptions[payer];
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
     * @dev Check if a payment is due for a subscription
     * @param subscriptionId The ID of the subscription
     * @return True if payment is due, false otherwise
     */
    function isPaymentDue(uint256 subscriptionId) external view returns (bool) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription memory sub = subscriptions[subscriptionId];
        
        return sub.status == SubscriptionStatus.ACTIVE && block.timestamp >= sub.nextPaymentTime;
    }
    
    /**
     * @dev Get time until next payment
     * @param subscriptionId The ID of the subscription
     * @return Time in seconds (0 if payment is due)
     */
    function getTimeUntilNextPayment(uint256 subscriptionId) external view returns (uint256) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription memory sub = subscriptions[subscriptionId];
        
        if (sub.status != SubscriptionStatus.ACTIVE || block.timestamp >= sub.nextPaymentTime) {
            return 0;
        }
        
        return sub.nextPaymentTime - block.timestamp;
    }
    
    /**
     * @dev Get all due subscriptions that can be executed
     * @return Array of subscription IDs that are due
     */
    function getDueSubscriptions() external view returns (uint256[] memory) {
        uint256 dueCount = 0;
        
        for (uint256 i = 1; i <= subscriptionCount; i++) {
            Subscription memory sub = subscriptions[i];
            if (sub.status == SubscriptionStatus.ACTIVE && 
                block.timestamp >= sub.nextPaymentTime &&
                address(this).balance >= sub.amount) {
                dueCount++;
            }
        }
        
        uint256[] memory dueSubs = new uint256[](dueCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= subscriptionCount; i++) {
            Subscription memory sub = subscriptions[i];
            if (sub.status == SubscriptionStatus.ACTIVE && 
                block.timestamp >= sub.nextPaymentTime &&
                address(this).balance >= sub.amount) {
                dueSubs[index] = i;
                index++;
            }
        }
        
        return dueSubs;
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Withdraw excess funds (only payer can withdraw their own funds)
     * @param subscriptionId The subscription ID to withdraw from
     * @param amount Amount to withdraw
     */
    function withdrawExcessFunds(uint256 subscriptionId, uint256 amount) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription memory sub = subscriptions[subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can withdraw");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}
}
