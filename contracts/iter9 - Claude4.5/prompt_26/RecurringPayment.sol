// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayment {
    enum Frequency { WEEKLY, MONTHLY }
    
    struct Subscription {
        uint256 id;
        address payer;
        address payee;
        uint256 amount;
        Frequency frequency;
        uint256 startTime;
        uint256 lastPaymentTime;
        uint256 nextPaymentTime;
        bool isActive;
        uint256 totalPaid;
        uint256 paymentCount;
    }
    
    uint256 public subscriptionCount;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public payerSubscriptions;
    mapping(address => uint256[]) public payeeSubscriptions;
    
    uint256 public constant WEEK = 7 days;
    uint256 public constant MONTH = 30 days;
    
    // Events
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        Frequency frequency
    );
    event PaymentProcessed(
        uint256 indexed subscriptionId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        uint256 paymentNumber
    );
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionUpdated(uint256 indexed subscriptionId, uint256 newAmount);
    event FundsDeposited(address indexed payer, uint256 amount);
    event FundsWithdrawn(address indexed payer, uint256 amount);
    
    mapping(address => uint256) public balances;
    
    /**
     * @dev Deposit funds to the contract
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw funds from the contract
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Create a recurring payment subscription
     * @param _payee The address to pay
     * @param _amount The payment amount
     * @param _frequency The payment frequency (0 = WEEKLY, 1 = MONTHLY)
     */
    function createSubscription(
        address _payee,
        uint256 _amount,
        Frequency _frequency
    ) external {
        require(_payee != address(0), "Invalid payee address");
        require(_payee != msg.sender, "Cannot subscribe to yourself");
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance for first payment");
        
        subscriptionCount++;
        
        uint256 interval = _frequency == Frequency.WEEKLY ? WEEK : MONTH;
        uint256 nextPayment = block.timestamp + interval;
        
        subscriptions[subscriptionCount] = Subscription({
            id: subscriptionCount,
            payer: msg.sender,
            payee: _payee,
            amount: _amount,
            frequency: _frequency,
            startTime: block.timestamp,
            lastPaymentTime: 0,
            nextPaymentTime: nextPayment,
            isActive: true,
            totalPaid: 0,
            paymentCount: 0
        });
        
        payerSubscriptions[msg.sender].push(subscriptionCount);
        payeeSubscriptions[_payee].push(subscriptionCount);
        
        emit SubscriptionCreated(subscriptionCount, msg.sender, _payee, _amount, _frequency);
    }
    
    /**
     * @dev Process a payment for a subscription
     * @param _subscriptionId The ID of the subscription
     */
    function processPayment(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(sub.isActive, "Subscription is not active");
        require(block.timestamp >= sub.nextPaymentTime, "Payment not due yet");
        require(balances[sub.payer] >= sub.amount, "Insufficient balance");
        
        // Process payment
        balances[sub.payer] -= sub.amount;
        balances[sub.payee] += sub.amount;
        
        sub.lastPaymentTime = block.timestamp;
        sub.totalPaid += sub.amount;
        sub.paymentCount++;
        
        // Calculate next payment time
        uint256 interval = sub.frequency == Frequency.WEEKLY ? WEEK : MONTH;
        sub.nextPaymentTime = block.timestamp + interval;
        
        emit PaymentProcessed(_subscriptionId, sub.payer, sub.payee, sub.amount, sub.paymentCount);
    }
    
    /**
     * @dev Cancel a subscription
     * @param _subscriptionId The ID of the subscription
     */
    function cancelSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer || msg.sender == sub.payee, "Not authorized");
        require(sub.isActive, "Subscription already cancelled");
        
        sub.isActive = false;
        
        emit SubscriptionCancelled(_subscriptionId);
    }
    
    /**
     * @dev Update subscription amount
     * @param _subscriptionId The ID of the subscription
     * @param _newAmount The new payment amount
     */
    function updateSubscriptionAmount(uint256 _subscriptionId, uint256 _newAmount) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        require(_newAmount > 0, "Amount must be greater than 0");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can update amount");
        require(sub.isActive, "Subscription is not active");
        
        sub.amount = _newAmount;
        
        emit SubscriptionUpdated(_subscriptionId, _newAmount);
    }
    
    /**
     * @dev Get subscription details
     * @param _subscriptionId The ID of the subscription
     * @return All subscription details
     */
    function getSubscription(uint256 _subscriptionId) external view returns (
        uint256 id,
        address payer,
        address payee,
        uint256 amount,
        Frequency frequency,
        uint256 startTime,
        uint256 lastPaymentTime,
        uint256 nextPaymentTime,
        bool isActive,
        uint256 totalPaid,
        uint256 paymentCount
    ) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return (
            sub.id,
            sub.payer,
            sub.payee,
            sub.amount,
            sub.frequency,
            sub.startTime,
            sub.lastPaymentTime,
            sub.nextPaymentTime,
            sub.isActive,
            sub.totalPaid,
            sub.paymentCount
        );
    }
    
    /**
     * @dev Get all subscriptions where the address is the payer
     * @param _payer The payer address
     * @return Array of subscription IDs
     */
    function getPayerSubscriptions(address _payer) external view returns (uint256[] memory) {
        return payerSubscriptions[_payer];
    }
    
    /**
     * @dev Get all subscriptions where the address is the payee
     * @param _payee The payee address
     * @return Array of subscription IDs
     */
    function getPayeeSubscriptions(address _payee) external view returns (uint256[] memory) {
        return payeeSubscriptions[_payee];
    }
    
    /**
     * @dev Check if a payment is due
     * @param _subscriptionId The ID of the subscription
     * @return True if payment is due, false otherwise
     */
    function isPaymentDue(uint256 _subscriptionId) external view returns (bool) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return sub.isActive && block.timestamp >= sub.nextPaymentTime;
    }
    
    /**
     * @dev Get time until next payment
     * @param _subscriptionId The ID of the subscription
     * @return Time in seconds (0 if payment is due)
     */
    function getTimeUntilNextPayment(uint256 _subscriptionId) external view returns (uint256) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        if (!sub.isActive || block.timestamp >= sub.nextPaymentTime) {
            return 0;
        }
        
        return sub.nextPaymentTime - block.timestamp;
    }
    
    /**
     * @dev Get user's balance
     * @param _user The user address
     * @return The balance
     */
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    /**
     * @dev Get active subscriptions for a payer
     * @param _payer The payer address
     * @return Array of active subscription IDs
     */
    function getActivePayerSubscriptions(address _payer) external view returns (uint256[] memory) {
        uint256[] memory allSubs = payerSubscriptions[_payer];
        uint256 activeCount = 0;
        
        // Count active subscriptions
        for (uint256 i = 0; i < allSubs.length; i++) {
            if (subscriptions[allSubs[i]].isActive) {
                activeCount++;
            }
        }
        
        uint256[] memory activeSubs = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            if (subscriptions[allSubs[i]].isActive) {
                activeSubs[index] = allSubs[i];
                index++;
            }
        }
        
        return activeSubs;
    }
    
    /**
     * @dev Get due subscriptions for processing
     * @param _payer The payer address
     * @return Array of subscription IDs that are due
     */
    function getDueSubscriptions(address _payer) external view returns (uint256[] memory) {
        uint256[] memory allSubs = payerSubscriptions[_payer];
        uint256 dueCount = 0;
        
        // Count due subscriptions
        for (uint256 i = 0; i < allSubs.length; i++) {
            Subscription memory sub = subscriptions[allSubs[i]];
            if (sub.isActive && block.timestamp >= sub.nextPaymentTime) {
                dueCount++;
            }
        }
        
        uint256[] memory dueSubs = new uint256[](dueCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allSubs.length; i++) {
            Subscription memory sub = subscriptions[allSubs[i]];
            if (sub.isActive && block.timestamp >= sub.nextPaymentTime) {
                dueSubs[index] = allSubs[i];
                index++;
            }
        }
        
        return dueSubs;
    }
}
