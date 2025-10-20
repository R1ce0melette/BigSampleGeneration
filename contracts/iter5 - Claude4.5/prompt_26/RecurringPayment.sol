// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayment {
    enum Frequency { WEEKLY, MONTHLY }
    enum SubscriptionStatus { ACTIVE, PAUSED, CANCELLED }
    
    struct Subscription {
        uint256 id;
        address payer;
        address payable recipient;
        uint256 amount;
        Frequency frequency;
        uint256 startTime;
        uint256 lastPaymentTime;
        uint256 nextPaymentTime;
        SubscriptionStatus status;
        uint256 totalPaid;
        uint256 paymentCount;
    }
    
    uint256 public subscriptionCount;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public payerSubscriptions;
    mapping(address => uint256[]) public recipientSubscriptions;
    
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed payer, address indexed recipient, uint256 amount, Frequency frequency);
    event PaymentProcessed(uint256 indexed subscriptionId, address indexed payer, address indexed recipient, uint256 amount);
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event FundsDeposited(address indexed payer, uint256 amount);
    
    function createSubscription(address payable _recipient, uint256 _amount, Frequency _frequency) external {
        require(_recipient != address(0), "Invalid recipient address");
        require(_recipient != msg.sender, "Cannot subscribe to yourself");
        require(_amount > 0, "Amount must be greater than zero");
        
        subscriptionCount++;
        
        uint256 interval = _frequency == Frequency.WEEKLY ? 7 days : 30 days;
        
        subscriptions[subscriptionCount] = Subscription({
            id: subscriptionCount,
            payer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            frequency: _frequency,
            startTime: block.timestamp,
            lastPaymentTime: 0,
            nextPaymentTime: block.timestamp,
            status: SubscriptionStatus.ACTIVE,
            totalPaid: 0,
            paymentCount: 0
        });
        
        payerSubscriptions[msg.sender].push(subscriptionCount);
        recipientSubscriptions[_recipient].push(subscriptionCount);
        
        emit SubscriptionCreated(subscriptionCount, msg.sender, _recipient, _amount, _frequency);
    }
    
    function processPayment(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        require(block.timestamp >= sub.nextPaymentTime, "Payment not due yet");
        require(address(this).balance >= sub.amount, "Insufficient contract balance");
        
        uint256 interval = sub.frequency == Frequency.WEEKLY ? 7 days : 30 days;
        
        sub.lastPaymentTime = block.timestamp;
        sub.nextPaymentTime = block.timestamp + interval;
        sub.totalPaid += sub.amount;
        sub.paymentCount++;
        
        (bool success, ) = sub.recipient.call{value: sub.amount}("");
        require(success, "Payment transfer failed");
        
        emit PaymentProcessed(_subscriptionId, sub.payer, sub.recipient, sub.amount);
    }
    
    function pauseSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can pause subscription");
        require(sub.status == SubscriptionStatus.ACTIVE, "Subscription is not active");
        
        sub.status = SubscriptionStatus.PAUSED;
        
        emit SubscriptionPaused(_subscriptionId);
    }
    
    function resumeSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can resume subscription");
        require(sub.status == SubscriptionStatus.PAUSED, "Subscription is not paused");
        
        uint256 interval = sub.frequency == Frequency.WEEKLY ? 7 days : 30 days;
        sub.nextPaymentTime = block.timestamp + interval;
        sub.status = SubscriptionStatus.ACTIVE;
        
        emit SubscriptionResumed(_subscriptionId);
    }
    
    function cancelSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription storage sub = subscriptions[_subscriptionId];
        
        require(msg.sender == sub.payer, "Only payer can cancel subscription");
        require(sub.status != SubscriptionStatus.CANCELLED, "Subscription is already cancelled");
        
        sub.status = SubscriptionStatus.CANCELLED;
        
        emit SubscriptionCancelled(_subscriptionId);
    }
    
    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit a positive amount");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function getSubscription(uint256 _subscriptionId) external view returns (
        uint256 id,
        address payer,
        address recipient,
        uint256 amount,
        Frequency frequency,
        uint256 nextPaymentTime,
        SubscriptionStatus status,
        uint256 totalPaid,
        uint256 paymentCount
    ) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return (
            sub.id,
            sub.payer,
            sub.recipient,
            sub.amount,
            sub.frequency,
            sub.nextPaymentTime,
            sub.status,
            sub.totalPaid,
            sub.paymentCount
        );
    }
    
    function getPayerSubscriptions(address _payer) external view returns (uint256[] memory) {
        return payerSubscriptions[_payer];
    }
    
    function getRecipientSubscriptions(address _recipient) external view returns (uint256[] memory) {
        return recipientSubscriptions[_recipient];
    }
    
    function isDueForPayment(uint256 _subscriptionId) external view returns (bool) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        return sub.status == SubscriptionStatus.ACTIVE && block.timestamp >= sub.nextPaymentTime;
    }
    
    function timeUntilNextPayment(uint256 _subscriptionId) external view returns (uint256) {
        require(_subscriptionId > 0 && _subscriptionId <= subscriptionCount, "Subscription does not exist");
        
        Subscription memory sub = subscriptions[_subscriptionId];
        
        if (sub.status != SubscriptionStatus.ACTIVE || block.timestamp >= sub.nextPaymentTime) {
            return 0;
        }
        
        return sub.nextPaymentTime - block.timestamp;
    }
    
    function getActiveSubscriptions() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= subscriptionCount; i++) {
            if (subscriptions[i].status == SubscriptionStatus.ACTIVE) {
                activeCount++;
            }
        }
        
        uint256[] memory activeIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= subscriptionCount; i++) {
            if (subscriptions[i].status == SubscriptionStatus.ACTIVE) {
                activeIds[index] = i;
                index++;
            }
        }
        
        return activeIds;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
