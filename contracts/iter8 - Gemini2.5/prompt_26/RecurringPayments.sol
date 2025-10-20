// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RecurringPayments
 * @dev A contract that allows users to set up and manage recurring ETH payments.
 */
contract RecurringPayments {
    enum Interval { Weekly, Monthly }

    struct Subscription {
        address payable recipient;
        uint256 amount;
        Interval interval;
        uint256 nextPaymentDate;
        uint256 balance; // Payer's deposited balance for this subscription
    }

    // Mapping from a payer's address to their subscription ID to the subscription details
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;
    mapping(address => uint256) public subscriptionCount;

    event Subscribed(address indexed payer, uint256 indexed subscriptionId, address indexed recipient, uint256 amount, Interval interval);
    event PaymentMade(address indexed payer, uint256 indexed subscriptionId, address indexed recipient, uint256 amount);
    event Canceled(address indexed payer, uint256 indexed subscriptionId);
    event Deposited(address indexed payer, uint256 indexed subscriptionId, uint256 amount);

    /**
     * @dev Creates a new recurring payment subscription.
     * @param _recipient The address to receive the payments.
     * @param _amount The amount for each payment.
     * @param _interval The frequency of payments (Weekly or Monthly).
     */
    function subscribe(address payable _recipient, uint256 _amount, Interval _interval) external {
        require(_recipient != address(0), "Recipient cannot be the zero address.");
        require(_amount > 0, "Payment amount must be greater than zero.");

        uint256 id = subscriptionCount[msg.sender]++;
        Subscription storage sub = subscriptions[msg.sender][id];
        
        sub.recipient = _recipient;
        sub.amount = _amount;
        sub.interval = _interval;
        sub.nextPaymentDate = block.timestamp + getIntervalSeconds(_interval);
        
        emit Subscribed(msg.sender, id, _recipient, _amount, _interval);
    }

    /**
     * @dev Deposits funds into a subscription to cover future payments.
     * @param _subscriptionId The ID of the subscription to fund.
     */
    function deposit(uint256 _subscriptionId) external payable {
        require(_subscriptionId < subscriptionCount[msg.sender], "Subscription does not exist.");
        require(msg.value > 0, "Deposit amount must be greater than zero.");

        subscriptions[msg.sender][_subscriptionId].balance += msg.value;
        emit Deposited(msg.sender, _subscriptionId, msg.value);
    }

    /**
     * @dev Processes a payment for a due subscription. Anyone can trigger this.
     * @param _payer The address of the person paying.
     * @param _subscriptionId The ID of the subscription to process.
     */
    function processPayment(address _payer, uint256 _subscriptionId) external {
        Subscription storage sub = subscriptions[_payer][_subscriptionId];
        require(_subscriptionId < subscriptionCount[_payer], "Subscription does not exist.");
        require(block.timestamp >= sub.nextPaymentDate, "Payment is not due yet.");
        require(sub.balance >= sub.amount, "Insufficient balance for payment.");

        sub.balance -= sub.amount;
        sub.nextPaymentDate += getIntervalSeconds(sub.interval);

        (bool success, ) = sub.recipient.call{value: sub.amount}("");
        require(success, "Payment transfer failed.");

        emit PaymentMade(_payer, _subscriptionId, sub.recipient, sub.amount);
    }

    /**
     * @dev Cancels a subscription and refunds the remaining balance to the payer.
     * @param _subscriptionId The ID of the subscription to cancel.
     */
    function cancelSubscription(uint256 _subscriptionId) external {
        require(_subscriptionId < subscriptionCount[msg.sender], "Subscription does not exist.");
        
        uint256 remainingBalance = subscriptions[msg.sender][_subscriptionId].balance;
        
        // Delete the subscription to prevent future payments
        delete subscriptions[msg.sender][_subscriptionId];

        if (remainingBalance > 0) {
            (bool success, ) = payable(msg.sender).call{value: remainingBalance}("");
            require(success, "Refund failed.");
        }
        
        emit Canceled(msg.sender, _subscriptionId);
    }

    function getIntervalSeconds(Interval _interval) private pure returns (uint256) {
        if (_interval == Interval.Weekly) {
            return 7 days;
        } else { // Monthly
            return 30 days; // Approximation for a month
        }
    }

    function getSubscription(uint256 _subscriptionId) external view returns (address, uint256, Interval, uint256, uint256) {
        Subscription storage sub = subscriptions[msg.sender][_subscriptionId];
        return (sub.recipient, sub.amount, sub.interval, sub.nextPaymentDate, sub.balance);
    }
}
