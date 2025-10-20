// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayment {
    enum PaymentInterval { WEEKLY, MONTHLY }
    
    struct Subscription {
        uint256 id;
        address payer;
        address payable recipient;
        uint256 amount;
        PaymentInterval interval;
        uint256 lastPaymentTime;
        uint256 nextPaymentTime;
        bool active;
        uint256 totalPaymentsMade;
        uint256 createdAt;
    }

    uint256 public subscriptionCount;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public payerSubscriptions;
    mapping(address => uint256[]) public recipientSubscriptions;

    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address indexed payer,
        address indexed recipient,
        uint256 amount,
        PaymentInterval interval
    );
    event PaymentProcessed(uint256 indexed subscriptionId, address indexed payer, address indexed recipient, uint256 amount);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionUpdated(uint256 indexed subscriptionId, uint256 newAmount);
    event FundsDeposited(address indexed payer, uint256 amount);

    function createSubscription(
        address payable recipient,
        uint256 amount,
        PaymentInterval interval
    ) external payable {
        require(recipient != address(0), "Invalid recipient address");
        require(recipient != msg.sender, "Cannot create subscription to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= amount, "Insufficient initial payment");

        subscriptionCount++;
        
        uint256 intervalSeconds = _getIntervalSeconds(interval);
        uint256 nextPaymentTime = block.timestamp + intervalSeconds;

        subscriptions[subscriptionCount] = Subscription({
            id: subscriptionCount,
            payer: msg.sender,
            recipient: recipient,
            amount: amount,
            interval: interval,
            lastPaymentTime: block.timestamp,
            nextPaymentTime: nextPaymentTime,
            active: true,
            totalPaymentsMade: 0,
            createdAt: block.timestamp
        });

        payerSubscriptions[msg.sender].push(subscriptionCount);
        recipientSubscriptions[recipient].push(subscriptionCount);

        // Process first payment
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Initial payment failed");

        subscriptions[subscriptionCount].totalPaymentsMade = 1;

        emit SubscriptionCreated(subscriptionCount, msg.sender, recipient, amount, interval);
        emit PaymentProcessed(subscriptionCount, msg.sender, recipient, amount);
    }

    function processPayment(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Subscription does not exist");
        Subscription storage subscription = subscriptions[subscriptionId];
        
        require(subscription.active, "Subscription is not active");
        require(block.timestamp >= subscription.nextPaymentTime, "Payment not due yet");
        require(address(this).balance >= subscription.amount, "Insufficient contract balance");

        uint256 intervalSeconds = _getIntervalSeconds(subscription.interval);
        
        subscription.lastPaymentTime = block.timestamp;
        subscription.nextPaymentTime = block.timestamp + intervalSeconds;
        subscription.totalPaymentsMade++;

        (bool success, ) = subscription.recipient.call{value: subscription.amount}("");
        require(success, "Payment transfer failed");

        emit PaymentProcessed(subscriptionId, subscription.payer, subscription.recipient, subscription.amount);
    }

    function cancelSubscription(uint256 subscriptionId) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Subscription does not exist");
        Subscription storage subscription = subscriptions[subscriptionId];
        
        require(msg.sender == subscription.payer, "Only payer can cancel subscription");
        require(subscription.active, "Subscription is already cancelled");

        subscription.active = false;

        emit SubscriptionCancelled(subscriptionId);
    }

    function updateSubscriptionAmount(uint256 subscriptionId, uint256 newAmount) external {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Subscription does not exist");
        Subscription storage subscription = subscriptions[subscriptionId];
        
        require(msg.sender == subscription.payer, "Only payer can update amount");
        require(subscription.active, "Subscription is not active");
        require(newAmount > 0, "Amount must be greater than 0");

        subscription.amount = newAmount;

        emit SubscriptionUpdated(subscriptionId, newAmount);
    }

    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit some funds");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate required balance for active subscriptions
        uint256 requiredBalance = 0;
        uint256[] memory subs = payerSubscriptions[msg.sender];
        
        for (uint256 i = 0; i < subs.length; i++) {
            Subscription memory sub = subscriptions[subs[i]];
            if (sub.active) {
                requiredBalance += sub.amount;
            }
        }

        require(address(this).balance - amount >= requiredBalance, "Cannot withdraw, needed for subscriptions");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getSubscription(uint256 subscriptionId) external view returns (
        uint256 id,
        address payer,
        address recipient,
        uint256 amount,
        PaymentInterval interval,
        uint256 lastPaymentTime,
        uint256 nextPaymentTime,
        bool active,
        uint256 totalPaymentsMade
    ) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Subscription does not exist");
        Subscription memory sub = subscriptions[subscriptionId];
        return (
            sub.id,
            sub.payer,
            sub.recipient,
            sub.amount,
            sub.interval,
            sub.lastPaymentTime,
            sub.nextPaymentTime,
            sub.active,
            sub.totalPaymentsMade
        );
    }

    function getPayerSubscriptions(address payer) external view returns (uint256[] memory) {
        return payerSubscriptions[payer];
    }

    function getRecipientSubscriptions(address recipient) external view returns (uint256[] memory) {
        return recipientSubscriptions[recipient];
    }

    function isPaymentDue(uint256 subscriptionId) external view returns (bool) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Subscription does not exist");
        Subscription memory sub = subscriptions[subscriptionId];
        return sub.active && block.timestamp >= sub.nextPaymentTime;
    }

    function getTimeUntilNextPayment(uint256 subscriptionId) external view returns (uint256) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCount, "Subscription does not exist");
        Subscription memory sub = subscriptions[subscriptionId];
        
        if (!sub.active || block.timestamp >= sub.nextPaymentTime) {
            return 0;
        }
        
        return sub.nextPaymentTime - block.timestamp;
    }

    function _getIntervalSeconds(PaymentInterval interval) private pure returns (uint256) {
        if (interval == PaymentInterval.WEEKLY) {
            return 7 days;
        } else {
            return 30 days;
        }
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
