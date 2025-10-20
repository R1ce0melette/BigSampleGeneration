// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayment {
    enum PaymentFrequency { WEEKLY, MONTHLY }
    enum SubscriptionStatus { ACTIVE, PAUSED, CANCELLED }
    
    struct Subscription {
        uint256 subscriptionId;
        address payer;
        address payee;
        uint256 amount;
        PaymentFrequency frequency;
        uint256 startTime;
        uint256 lastPaymentTime;
        uint256 nextPaymentTime;
        SubscriptionStatus status;
        uint256 totalPaymentsMade;
        uint256 totalAmountPaid;
    }
    
    uint256 public subscriptionCount;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public payerSubscriptions;
    mapping(address => uint256[]) public payeeSubscriptions;
    
    uint256 public constant WEEK = 7 days;
    uint256 public constant MONTH = 30 days;
    
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, PaymentFrequency frequency);
    event PaymentProcessed(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, uint256 timestamp);
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionUpdated(uint256 indexed subscriptionId, uint256 newAmount);
    
    modifier onlyPayer(uint256 _subscriptionId) {
        require(subscriptions[_subscriptionId].payer == msg.sender, "Only payer can call this");
        _;
    }
    
    modifier subscriptionExists(uint256 _subscriptionId) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Invalid subscription ID");
        _;
    }
    
    function createSubscription(
        address _payee,
        uint256 _amount,
        PaymentFrequency _frequency
    ) external payable returns (uint256) {
        require(_payee != address(0), "Payee cannot be zero address");
        require(_payee != msg.sender, "Cannot create subscription to yourself");
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value >= _amount, "Must deposit at least one payment amount");
        
        subscriptionCount++;
        
        uint256 interval = _frequency == PaymentFrequency.WEEKLY ? WEEK : MONTH;
        uint256 nextPayment = block.timestamp + interval;
        
        subscriptions[subscriptionCount] = Subscription({
            subscriptionId: subscriptionCount,
            payer: msg.sender,
            payee: _payee,
            amount: _amount,
            frequency: _frequency,
            startTime: block.timestamp,
            lastPaymentTime: 0,
            nextPaymentTime: nextPayment,
            status: SubscriptionStatus.ACTIVE,
            totalPaymentsMade: 0,
            totalAmountPaid: 0
        });
        
        payerSubscriptions[msg.sender].push(subscriptionCount);
        payeeSubscriptions[_payee].push(subscriptionCount);
        
        emit SubscriptionCreated(subscriptionCount, msg.sender, _payee, _amount, _frequency);
        
        return subscriptionCount;
    }
    
    function deposit(uint256 _subscriptionId) external payable 
        subscriptionExists(_subscriptionId) 
        onlyPayer(_subscriptionId) 
    {
        require(msg.value > 0, "Deposit amount must be greater than 0");
    }
    
    function processPayment(uint256 _subscriptionId) external subscriptionExists(_subscriptionId) {
        Subscription storage subscription = subscriptions[_subscriptionId];
        
        require(subscription.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        require(block.timestamp >= subscription.nextPaymentTime, "Payment not due yet");
        
        uint256 balance = getSubscriptionBalance(_subscriptionId);
        require(balance >= subscription.amount, "Insufficient balance for payment");
        
        subscription.lastPaymentTime = block.timestamp;
        subscription.totalPaymentsMade++;
        subscription.totalAmountPaid += subscription.amount;
        
        uint256 interval = subscription.frequency == PaymentFrequency.WEEKLY ? WEEK : MONTH;
        subscription.nextPaymentTime = block.timestamp + interval;
        
        (bool success, ) = subscription.payee.call{value: subscription.amount}("");
        require(success, "Payment transfer failed");
        
        emit PaymentProcessed(_subscriptionId, subscription.payer, subscription.payee, subscription.amount, block.timestamp);
    }
    
    function pauseSubscription(uint256 _subscriptionId) external 
        subscriptionExists(_subscriptionId) 
        onlyPayer(_subscriptionId) 
    {
        require(subscriptions[_subscriptionId].status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        
        subscriptions[_subscriptionId].status = SubscriptionStatus.PAUSED;
        
        emit SubscriptionPaused(_subscriptionId);
    }
    
    function resumeSubscription(uint256 _subscriptionId) external 
        subscriptionExists(_subscriptionId) 
        onlyPayer(_subscriptionId) 
    {
        Subscription storage subscription = subscriptions[_subscriptionId];
        require(subscription.status == SubscriptionStatus.PAUSED, "Subscription is not paused");
        
        subscription.status = SubscriptionStatus.ACTIVE;
        
        // Reset next payment time from now
        uint256 interval = subscription.frequency == PaymentFrequency.WEEKLY ? WEEK : MONTH;
        subscription.nextPaymentTime = block.timestamp + interval;
        
        emit SubscriptionResumed(_subscriptionId);
    }
    
    function cancelSubscription(uint256 _subscriptionId) external 
        subscriptionExists(_subscriptionId) 
        onlyPayer(_subscriptionId) 
    {
        Subscription storage subscription = subscriptions[_subscriptionId];
        require(subscription.status != SubscriptionStatus.CANCELLED, "Subscription already cancelled");
        
        subscription.status = SubscriptionStatus.CANCELLED;
        
        // Refund remaining balance
        uint256 balance = getSubscriptionBalance(_subscriptionId);
        if (balance > 0) {
            (bool success, ) = subscription.payer.call{value: balance}("");
            require(success, "Refund transfer failed");
        }
        
        emit SubscriptionCancelled(_subscriptionId);
    }
    
    function updateSubscriptionAmount(uint256 _subscriptionId, uint256 _newAmount) external 
        subscriptionExists(_subscriptionId) 
        onlyPayer(_subscriptionId) 
    {
        require(_newAmount > 0, "Amount must be greater than 0");
        Subscription storage subscription = subscriptions[_subscriptionId];
        require(subscription.status == SubscriptionStatus.ACTIVE || subscription.status == SubscriptionStatus.PAUSED, "Subscription is cancelled");
        
        subscription.amount = _newAmount;
        
        emit SubscriptionUpdated(_subscriptionId, _newAmount);
    }
    
    function withdrawRefund(uint256 _subscriptionId) external 
        subscriptionExists(_subscriptionId) 
        onlyPayer(_subscriptionId) 
    {
        Subscription storage subscription = subscriptions[_subscriptionId];
        require(subscription.status == SubscriptionStatus.CANCELLED, "Subscription must be cancelled");
        
        uint256 balance = getSubscriptionBalance(_subscriptionId);
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = subscription.payer.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    function getSubscription(uint256 _subscriptionId) external view subscriptionExists(_subscriptionId) returns (
        address payer,
        address payee,
        uint256 amount,
        PaymentFrequency frequency,
        uint256 startTime,
        uint256 lastPaymentTime,
        uint256 nextPaymentTime,
        SubscriptionStatus status,
        uint256 totalPaymentsMade,
        uint256 totalAmountPaid,
        uint256 balance
    ) {
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return (
            sub.payer,
            sub.payee,
            sub.amount,
            sub.frequency,
            sub.startTime,
            sub.lastPaymentTime,
            sub.nextPaymentTime,
            sub.status,
            sub.totalPaymentsMade,
            sub.totalAmountPaid,
            getSubscriptionBalance(_subscriptionId)
        );
    }
    
    function getSubscriptionBalance(uint256 _subscriptionId) public view subscriptionExists(_subscriptionId) returns (uint256) {
        return address(this).balance;
    }
    
    function getPayerSubscriptions(address _payer) external view returns (uint256[] memory) {
        return payerSubscriptions[_payer];
    }
    
    function getPayeeSubscriptions(address _payee) external view returns (uint256[] memory) {
        return payeeSubscriptions[_payee];
    }
    
    function isPaymentDue(uint256 _subscriptionId) external view subscriptionExists(_subscriptionId) returns (bool) {
        Subscription memory subscription = subscriptions[_subscriptionId];
        return subscription.status == SubscriptionStatus.ACTIVE && 
               block.timestamp >= subscription.nextPaymentTime;
    }
    
    function getTimeUntilNextPayment(uint256 _subscriptionId) external view subscriptionExists(_subscriptionId) returns (uint256) {
        Subscription memory subscription = subscriptions[_subscriptionId];
        
        if (subscription.status != SubscriptionStatus.ACTIVE) {
            return 0;
        }
        
        if (block.timestamp >= subscription.nextPaymentTime) {
            return 0;
        }
        
        return subscription.nextPaymentTime - block.timestamp;
    }
    
    receive() external payable {}
}
