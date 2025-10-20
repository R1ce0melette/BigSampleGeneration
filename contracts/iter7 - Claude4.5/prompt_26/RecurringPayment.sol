// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RecurringPayment
 * @dev A contract for recurring payment system where users can authorize weekly or monthly payments to another address
 */
contract RecurringPayment {
    // Payment frequency enum
    enum Frequency {
        WEEKLY,
        MONTHLY
    }
    
    // Subscription structure
    struct Subscription {
        uint256 id;
        address payer;
        address payable recipient;
        uint256 amount;
        Frequency frequency;
        uint256 startTime;
        uint256 lastPaymentTime;
        uint256 totalPaid;
        uint256 paymentCount;
        bool active;
    }
    
    // State variables
    uint256 public subscriptionCount;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public payerSubscriptions;
    mapping(address => uint256[]) public recipientSubscriptions;
    
    // Events
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed payer, address indexed recipient, uint256 amount, Frequency frequency);
    event PaymentProcessed(uint256 indexed subscriptionId, address indexed payer, address indexed recipient, uint256 amount, uint256 timestamp);
    event SubscriptionCancelled(uint256 indexed subscriptionId, address indexed cancelledBy);
    event FundsDeposited(address indexed payer, uint256 amount);
    event FundsWithdrawn(address indexed payer, uint256 amount);
    
    // User balances for recurring payments
    mapping(address => uint256) public balances;
    
    /**
     * @dev Deposit funds for recurring payments
     */
    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit funds");
        
        balances[msg.sender] += msg.value;
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw unused funds
     * @param amount The amount to withdraw
     */
    function withdrawFunds(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Create a recurring payment subscription
     * @param recipient The recipient address
     * @param amount The payment amount
     * @param frequency The payment frequency (WEEKLY or MONTHLY)
     * @return subscriptionId The ID of the created subscription
     */
    function createSubscription(
        address payable recipient,
        uint256 amount,
        Frequency frequency
    ) external returns (uint256) {
        require(recipient != address(0), "Invalid recipient address");
        require(recipient != msg.sender, "Cannot subscribe to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance for first payment");
        
        subscriptionCount++;
        uint256 subscriptionId = subscriptionCount;
        
        subscriptions[subscriptionId] = Subscription({
            id: subscriptionId,
            payer: msg.sender,
            recipient: recipient,
            amount: amount,
            frequency: frequency,
            startTime: block.timestamp,
            lastPaymentTime: 0,
            totalPaid: 0,
            paymentCount: 0,
            active: true
        });
        
        payerSubscriptions[msg.sender].push(subscriptionId);
        recipientSubscriptions[recipient].push(subscriptionId);
        
        emit SubscriptionCreated(subscriptionId, msg.sender, recipient, amount, frequency);
        
        return subscriptionId;
    }
    
    /**
     * @dev Process a payment for a subscription
     * @param subscriptionId The ID of the subscription
     */
    function processPayment(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.active, "Subscription is not active");
        require(canProcessPayment(subscriptionId), "Payment not yet due");
        require(balances[sub.payer] >= sub.amount, "Insufficient payer balance");
        
        // Transfer funds
        balances[sub.payer] -= sub.amount;
        
        (bool success, ) = sub.recipient.call{value: sub.amount}("");
        require(success, "Transfer to recipient failed");
        
        // Update subscription
        sub.lastPaymentTime = block.timestamp;
        sub.totalPaid += sub.amount;
        sub.paymentCount++;
        
        emit PaymentProcessed(subscriptionId, sub.payer, sub.recipient, sub.amount, block.timestamp);
    }
    
    /**
     * @dev Check if a payment can be processed
     * @param subscriptionId The ID of the subscription
     * @return True if payment can be processed, false otherwise
     */
    function canProcessPayment(uint256 subscriptionId) public view returns (bool) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription memory sub = subscriptions[subscriptionId];
        
        if (!sub.active) {
            return false;
        }
        
        // First payment
        if (sub.lastPaymentTime == 0) {
            return true;
        }
        
        uint256 interval;
        if (sub.frequency == Frequency.WEEKLY) {
            interval = 7 days;
        } else {
            interval = 30 days;
        }
        
        return block.timestamp >= sub.lastPaymentTime + interval;
    }
    
    /**
     * @dev Cancel a subscription
     * @param subscriptionId The ID of the subscription
     */
    function cancelSubscription(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription storage sub = subscriptions[subscriptionId];
        
        require(sub.active, "Subscription already cancelled");
        require(msg.sender == sub.payer || msg.sender == sub.recipient, "Only payer or recipient can cancel");
        
        sub.active = false;
        
        emit SubscriptionCancelled(subscriptionId, msg.sender);
    }
    
    /**
     * @dev Get subscription details
     * @param subscriptionId The ID of the subscription
     * @return id Subscription ID
     * @return payer Payer's address
     * @return recipient Recipient's address
     * @return amount Payment amount
     * @return frequency Payment frequency
     * @return startTime Start timestamp
     * @return lastPaymentTime Last payment timestamp
     * @return totalPaid Total amount paid
     * @return paymentCount Number of payments made
     * @return active Whether subscription is active
     */
    function getSubscription(uint256 subscriptionId) external view returns (
        uint256 id,
        address payer,
        address recipient,
        uint256 amount,
        Frequency frequency,
        uint256 startTime,
        uint256 lastPaymentTime,
        uint256 totalPaid,
        uint256 paymentCount,
        bool active
    ) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[subscriptionId];
        return (
            sub.id,
            sub.payer,
            sub.recipient,
            sub.amount,
            sub.frequency,
            sub.startTime,
            sub.lastPaymentTime,
            sub.totalPaid,
            sub.paymentCount,
            sub.active
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
     * @dev Get all subscriptions where caller is the recipient
     * @return Array of subscription IDs
     */
    function getMyRecipientSubscriptions() external view returns (uint256[] memory) {
        return recipientSubscriptions[msg.sender];
    }
    
    /**
     * @dev Get subscriptions by payer
     * @param payer The payer's address
     * @return Array of subscription IDs
     */
    function getSubscriptionsByPayer(address payer) external view returns (uint256[] memory) {
        return payerSubscriptions[payer];
    }
    
    /**
     * @dev Get subscriptions by recipient
     * @param recipient The recipient's address
     * @return Array of subscription IDs
     */
    function getSubscriptionsByRecipient(address recipient) external view returns (uint256[] memory) {
        return recipientSubscriptions[recipient];
    }
    
    /**
     * @dev Get active subscriptions for payer
     * @param payer The payer's address
     * @return Array of active subscription IDs
     */
    function getActiveSubscriptionsByPayer(address payer) external view returns (uint256[] memory) {
        uint256[] memory allSubs = payerSubscriptions[payer];
        uint256 activeCount = 0;
        
        // Count active subscriptions
        for (uint256 i = 0; i < allSubs.length; i++) {
            if (subscriptions[allSubs[i]].active) {
                activeCount++;
            }
        }
        
        // Create array of active subscription IDs
        uint256[] memory activeSubs = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            if (subscriptions[allSubs[i]].active) {
                activeSubs[index] = allSubs[i];
                index++;
            }
        }
        
        return activeSubs;
    }
    
    /**
     * @dev Get time until next payment
     * @param subscriptionId The ID of the subscription
     * @return The time remaining in seconds, or 0 if payment is due
     */
    function getTimeUntilNextPayment(uint256 subscriptionId) external view returns (uint256) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Invalid subscription ID");
        Subscription memory sub = subscriptions[subscriptionId];
        
        if (!sub.active) {
            return 0;
        }
        
        if (sub.lastPaymentTime == 0) {
            return 0; // First payment can be made immediately
        }
        
        uint256 interval;
        if (sub.frequency == Frequency.WEEKLY) {
            interval = 7 days;
        } else {
            interval = 30 days;
        }
        
        uint256 nextPaymentTime = sub.lastPaymentTime + interval;
        
        if (block.timestamp >= nextPaymentTime) {
            return 0;
        }
        
        return nextPaymentTime - block.timestamp;
    }
    
    /**
     * @dev Get caller's balance
     * @return The caller's balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Get total amount committed to active subscriptions for a payer
     * @param payer The payer's address
     * @return The total committed amount
     */
    function getTotalCommitment(address payer) external view returns (uint256) {
        uint256[] memory subs = payerSubscriptions[payer];
        uint256 total = 0;
        
        for (uint256 i = 0; i < subs.length; i++) {
            if (subscriptions[subs[i]].active) {
                total += subscriptions[subs[i]].amount;
            }
        }
        
        return total;
    }
    
    /**
     * @dev Batch process multiple payments
     * @param subscriptionIds Array of subscription IDs to process
     */
    function batchProcessPayments(uint256[] memory subscriptionIds) external {
        require(subscriptionIds.length > 0, "No subscriptions provided");
        
        for (uint256 i = 0; i < subscriptionIds.length; i++) {
            uint256 subId = subscriptionIds[i];
            
            if (subId > 0 && subId <= subscriptionCount) {
                Subscription storage sub = subscriptions[subId];
                
                if (sub.active && canProcessPayment(subId) && balances[sub.payer] >= sub.amount) {
                    balances[sub.payer] -= sub.amount;
                    
                    (bool success, ) = sub.recipient.call{value: sub.amount}("");
                    if (success) {
                        sub.lastPaymentTime = block.timestamp;
                        sub.totalPaid += sub.amount;
                        sub.paymentCount++;
                        
                        emit PaymentProcessed(subId, sub.payer, sub.recipient, sub.amount, block.timestamp);
                    } else {
                        // Refund if transfer fails
                        balances[sub.payer] += sub.amount;
                    }
                }
            }
        }
    }
    
    /**
     * @dev Receive ETH (add to caller's balance)
     */
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }
}
