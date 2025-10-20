// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RecurringPaymentSystem
 * @dev Contract for recurring payment system where users can authorize weekly or monthly payments to another address
 */
contract RecurringPaymentSystem {
    // Payment frequency enum
    enum Frequency {
        Weekly,
        Monthly
    }

    // Subscription status enum
    enum SubscriptionStatus {
        Active,
        Paused,
        Cancelled
    }

    // Subscription structure
    struct Subscription {
        uint256 id;
        address payer;
        address payee;
        uint256 amount;
        Frequency frequency;
        uint256 startTime;
        uint256 nextPaymentTime;
        uint256 lastPaymentTime;
        SubscriptionStatus status;
        uint256 totalPaymentsMade;
        uint256 totalAmountPaid;
        uint256 createdAt;
    }

    // Payment record
    struct Payment {
        uint256 id;
        uint256 subscriptionId;
        address payer;
        address payee;
        uint256 amount;
        uint256 timestamp;
    }

    // User statistics
    struct UserStats {
        uint256 subscriptionsCreated;
        uint256 subscriptionsReceiving;
        uint256 totalPaid;
        uint256 totalReceived;
    }

    // State variables
    address public owner;
    uint256 private subscriptionCounter;
    uint256 private paymentCounter;
    
    uint256 public constant WEEK_DURATION = 7 days;
    uint256 public constant MONTH_DURATION = 30 days;
    
    mapping(uint256 => Subscription) private subscriptions;
    mapping(address => uint256[]) private payerSubscriptions;
    mapping(address => uint256[]) private payeeSubscriptions;
    mapping(uint256 => Payment[]) private subscriptionPayments;
    mapping(address => UserStats) private userStats;
    
    uint256[] private allSubscriptionIds;
    Payment[] private allPayments;

    // Events
    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed payer, address indexed payee, uint256 amount, Frequency frequency);
    event PaymentProcessed(uint256 indexed subscriptionId, uint256 indexed paymentId, address indexed payer, address payee, uint256 amount);
    event SubscriptionPaused(uint256 indexed subscriptionId, address indexed payer);
    event SubscriptionResumed(uint256 indexed subscriptionId, address indexed payer);
    event SubscriptionCancelled(uint256 indexed subscriptionId, address indexed payer);
    event SubscriptionUpdated(uint256 indexed subscriptionId, uint256 newAmount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier subscriptionExists(uint256 subscriptionId) {
        require(subscriptionId > 0 && subscriptionId <= subscriptionCounter, "Subscription does not exist");
        _;
    }

    modifier onlyPayer(uint256 subscriptionId) {
        require(subscriptions[subscriptionId].payer == msg.sender, "Not the payer");
        _;
    }

    modifier subscriptionActive(uint256 subscriptionId) {
        require(subscriptions[subscriptionId].status == SubscriptionStatus.Active, "Subscription is not active");
        _;
    }

    constructor() {
        owner = msg.sender;
        subscriptionCounter = 0;
        paymentCounter = 0;
    }

    /**
     * @dev Create a new subscription
     * @param payee Recipient address
     * @param amount Payment amount
     * @param frequency Payment frequency (0: Weekly, 1: Monthly)
     * @return subscriptionId ID of the created subscription
     */
    function createSubscription(
        address payee,
        uint256 amount,
        Frequency frequency
    ) public payable returns (uint256) {
        require(payee != address(0), "Invalid payee address");
        require(payee != msg.sender, "Cannot subscribe to yourself");
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= amount, "Insufficient initial payment");

        subscriptionCounter++;
        uint256 subscriptionId = subscriptionCounter;

        uint256 interval = frequency == Frequency.Weekly ? WEEK_DURATION : MONTH_DURATION;
        uint256 nextPayment = block.timestamp + interval;

        Subscription storage newSubscription = subscriptions[subscriptionId];
        newSubscription.id = subscriptionId;
        newSubscription.payer = msg.sender;
        newSubscription.payee = payee;
        newSubscription.amount = amount;
        newSubscription.frequency = frequency;
        newSubscription.startTime = block.timestamp;
        newSubscription.nextPaymentTime = nextPayment;
        newSubscription.lastPaymentTime = block.timestamp;
        newSubscription.status = SubscriptionStatus.Active;
        newSubscription.totalPaymentsMade = 1;
        newSubscription.totalAmountPaid = amount;
        newSubscription.createdAt = block.timestamp;

        payerSubscriptions[msg.sender].push(subscriptionId);
        payeeSubscriptions[payee].push(subscriptionId);
        allSubscriptionIds.push(subscriptionId);

        // Process first payment
        payable(payee).transfer(amount);

        // Record payment
        _recordPayment(subscriptionId, msg.sender, payee, amount);

        // Update statistics
        userStats[msg.sender].subscriptionsCreated++;
        userStats[msg.sender].totalPaid += amount;
        userStats[payee].subscriptionsReceiving++;
        userStats[payee].totalReceived += amount;

        // Refund excess if any
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }

        emit SubscriptionCreated(subscriptionId, msg.sender, payee, amount, frequency);

        return subscriptionId;
    }

    /**
     * @dev Process a recurring payment
     * @param subscriptionId Subscription ID
     */
    function processPayment(uint256 subscriptionId) 
        public 
        payable 
        subscriptionExists(subscriptionId)
        subscriptionActive(subscriptionId)
    {
        Subscription storage subscription = subscriptions[subscriptionId];
        
        require(block.timestamp >= subscription.nextPaymentTime, "Payment not due yet");
        require(msg.sender == subscription.payer, "Only payer can process payment");
        require(msg.value >= subscription.amount, "Insufficient payment amount");

        // Process payment
        payable(subscription.payee).transfer(subscription.amount);

        // Update subscription
        uint256 interval = subscription.frequency == Frequency.Weekly ? WEEK_DURATION : MONTH_DURATION;
        subscription.lastPaymentTime = block.timestamp;
        subscription.nextPaymentTime = block.timestamp + interval;
        subscription.totalPaymentsMade++;
        subscription.totalAmountPaid += subscription.amount;

        // Record payment
        _recordPayment(subscriptionId, subscription.payer, subscription.payee, subscription.amount);

        // Update statistics
        userStats[subscription.payer].totalPaid += subscription.amount;
        userStats[subscription.payee].totalReceived += subscription.amount;

        // Refund excess if any
        if (msg.value > subscription.amount) {
            payable(msg.sender).transfer(msg.value - subscription.amount);
        }

        emit PaymentProcessed(subscriptionId, paymentCounter, subscription.payer, subscription.payee, subscription.amount);
    }

    /**
     * @dev Internal function to record payment
     * @param subscriptionId Subscription ID
     * @param payer Payer address
     * @param payee Payee address
     * @param amount Payment amount
     */
    function _recordPayment(
        uint256 subscriptionId,
        address payer,
        address payee,
        uint256 amount
    ) private {
        paymentCounter++;

        Payment memory payment = Payment({
            id: paymentCounter,
            subscriptionId: subscriptionId,
            payer: payer,
            payee: payee,
            amount: amount,
            timestamp: block.timestamp
        });

        subscriptionPayments[subscriptionId].push(payment);
        allPayments.push(payment);
    }

    /**
     * @dev Pause a subscription
     * @param subscriptionId Subscription ID
     */
    function pauseSubscription(uint256 subscriptionId) 
        public 
        subscriptionExists(subscriptionId)
        onlyPayer(subscriptionId)
        subscriptionActive(subscriptionId)
    {
        subscriptions[subscriptionId].status = SubscriptionStatus.Paused;

        emit SubscriptionPaused(subscriptionId, msg.sender);
    }

    /**
     * @dev Resume a paused subscription
     * @param subscriptionId Subscription ID
     */
    function resumeSubscription(uint256 subscriptionId) 
        public 
        subscriptionExists(subscriptionId)
        onlyPayer(subscriptionId)
    {
        Subscription storage subscription = subscriptions[subscriptionId];
        require(subscription.status == SubscriptionStatus.Paused, "Subscription is not paused");

        subscription.status = SubscriptionStatus.Active;
        
        // Recalculate next payment time from now
        uint256 interval = subscription.frequency == Frequency.Weekly ? WEEK_DURATION : MONTH_DURATION;
        subscription.nextPaymentTime = block.timestamp + interval;

        emit SubscriptionResumed(subscriptionId, msg.sender);
    }

    /**
     * @dev Cancel a subscription
     * @param subscriptionId Subscription ID
     */
    function cancelSubscription(uint256 subscriptionId) 
        public 
        subscriptionExists(subscriptionId)
        onlyPayer(subscriptionId)
    {
        require(
            subscriptions[subscriptionId].status != SubscriptionStatus.Cancelled,
            "Subscription already cancelled"
        );

        subscriptions[subscriptionId].status = SubscriptionStatus.Cancelled;

        emit SubscriptionCancelled(subscriptionId, msg.sender);
    }

    /**
     * @dev Update subscription amount
     * @param subscriptionId Subscription ID
     * @param newAmount New payment amount
     */
    function updateSubscriptionAmount(uint256 subscriptionId, uint256 newAmount) 
        public 
        subscriptionExists(subscriptionId)
        onlyPayer(subscriptionId)
    {
        require(newAmount > 0, "Amount must be greater than 0");
        require(
            subscriptions[subscriptionId].status != SubscriptionStatus.Cancelled,
            "Cannot update cancelled subscription"
        );

        subscriptions[subscriptionId].amount = newAmount;

        emit SubscriptionUpdated(subscriptionId, newAmount);
    }

    /**
     * @dev Get subscription details
     * @param subscriptionId Subscription ID
     * @return Subscription details
     */
    function getSubscription(uint256 subscriptionId) 
        public 
        view 
        subscriptionExists(subscriptionId)
        returns (Subscription memory) 
    {
        return subscriptions[subscriptionId];
    }

    /**
     * @dev Get subscriptions where user is the payer
     * @param payer Payer address
     * @return Array of subscription IDs
     */
    function getPayerSubscriptions(address payer) public view returns (uint256[] memory) {
        return payerSubscriptions[payer];
    }

    /**
     * @dev Get subscriptions where user is the payee
     * @param payee Payee address
     * @return Array of subscription IDs
     */
    function getPayeeSubscriptions(address payee) public view returns (uint256[] memory) {
        return payeeSubscriptions[payee];
    }

    /**
     * @dev Get subscription payment history
     * @param subscriptionId Subscription ID
     * @return Array of payments
     */
    function getSubscriptionPayments(uint256 subscriptionId) 
        public 
        view 
        subscriptionExists(subscriptionId)
        returns (Payment[] memory) 
    {
        return subscriptionPayments[subscriptionId];
    }

    /**
     * @dev Get all payments
     * @return Array of all payments
     */
    function getAllPayments() public view returns (Payment[] memory) {
        return allPayments;
    }

    /**
     * @dev Get all subscriptions
     * @return Array of all subscriptions
     */
    function getAllSubscriptions() public view returns (Subscription[] memory) {
        Subscription[] memory allSubscriptions = new Subscription[](allSubscriptionIds.length);
        
        for (uint256 i = 0; i < allSubscriptionIds.length; i++) {
            allSubscriptions[i] = subscriptions[allSubscriptionIds[i]];
        }
        
        return allSubscriptions;
    }

    /**
     * @dev Get active subscriptions
     * @return Array of active subscriptions
     */
    function getActiveSubscriptions() public view returns (Subscription[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allSubscriptionIds.length; i++) {
            if (subscriptions[allSubscriptionIds[i]].status == SubscriptionStatus.Active) {
                count++;
            }
        }

        Subscription[] memory result = new Subscription[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allSubscriptionIds.length; i++) {
            Subscription memory subscription = subscriptions[allSubscriptionIds[i]];
            if (subscription.status == SubscriptionStatus.Active) {
                result[index] = subscription;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get due subscriptions (payments that are ready to be processed)
     * @return Array of due subscriptions
     */
    function getDueSubscriptions() public view returns (Subscription[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allSubscriptionIds.length; i++) {
            Subscription memory subscription = subscriptions[allSubscriptionIds[i]];
            if (subscription.status == SubscriptionStatus.Active && 
                block.timestamp >= subscription.nextPaymentTime) {
                count++;
            }
        }

        Subscription[] memory result = new Subscription[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allSubscriptionIds.length; i++) {
            Subscription memory subscription = subscriptions[allSubscriptionIds[i]];
            if (subscription.status == SubscriptionStatus.Active && 
                block.timestamp >= subscription.nextPaymentTime) {
                result[index] = subscription;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return UserStats details
     */
    function getUserStats(address user) public view returns (UserStats memory) {
        return userStats[user];
    }

    /**
     * @dev Check if subscription payment is due
     * @param subscriptionId Subscription ID
     * @return true if payment is due
     */
    function isPaymentDue(uint256 subscriptionId) 
        public 
        view 
        subscriptionExists(subscriptionId)
        returns (bool) 
    {
        Subscription memory subscription = subscriptions[subscriptionId];
        return subscription.status == SubscriptionStatus.Active && 
               block.timestamp >= subscription.nextPaymentTime;
    }

    /**
     * @dev Get time until next payment
     * @param subscriptionId Subscription ID
     * @return Seconds until next payment (0 if due or overdue)
     */
    function getTimeUntilNextPayment(uint256 subscriptionId) 
        public 
        view 
        subscriptionExists(subscriptionId)
        returns (uint256) 
    {
        Subscription memory subscription = subscriptions[subscriptionId];
        if (block.timestamp >= subscription.nextPaymentTime) {
            return 0;
        }
        return subscription.nextPaymentTime - block.timestamp;
    }

    /**
     * @dev Get total subscription count
     * @return Total number of subscriptions
     */
    function getTotalSubscriptionCount() public view returns (uint256) {
        return subscriptionCounter;
    }

    /**
     * @dev Get total payment count
     * @return Total number of payments
     */
    function getTotalPaymentCount() public view returns (uint256) {
        return paymentCounter;
    }

    /**
     * @dev Get active subscription count
     * @return Number of active subscriptions
     */
    function getActiveSubscriptionCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allSubscriptionIds.length; i++) {
            if (subscriptions[allSubscriptionIds[i]].status == SubscriptionStatus.Active) {
                count++;
            }
        }
        return count;
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
