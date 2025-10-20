// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RecurringPayments
 * @dev A contract that allows users to set up and manage recurring
 * weekly or monthly payments to a specified recipient.
 */
contract RecurringPayments {
    enum Interval { Weekly, Monthly }

    struct Subscription {
        address recipient;
        uint256 amount;
        Interval interval;
        uint256 nextPaymentTime;
        bool isActive;
    }

    // Mapping from a subscriber's address to their subscription details
    mapping(address => Subscription) public subscriptions;

    address public owner;

    uint256 constant WEEKLY_INTERVAL = 7 days;
    uint256 constant MONTHLY_INTERVAL = 30 days;

    /**
     * @dev Emitted when a new subscription is created or updated.
     * @param subscriber The address of the user setting up the payment.
     * @param recipient The address receiving the payments.
     * @param amount The amount per payment.
     * @param interval The frequency of the payment (Weekly or Monthly).
     */
    event SubscriptionSet(
        address indexed subscriber,
        address indexed recipient,
        uint256 amount,
        Interval interval
    );

    /**
     * @dev Emitted when a subscription is cancelled.
     * @param subscriber The address of the user who cancelled.
     */
    event SubscriptionCancelled(address indexed subscriber);

    /**
     * @dev Emitted when a payment is successfully processed.
     * @param subscriber The address of the payer.
     * @param recipient The address of the recipient.
     * @param amount The amount paid.
     */
    event PaymentMade(
        address indexed subscriber,
        address indexed recipient,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Sets up or updates a recurring payment subscription.
     * The user must send enough ETH to cover at least the first payment.
     * @param _recipient The address to receive the payments.
     * @param _interval The payment interval (0 for Weekly, 1 for Monthly).
     */
    function setSubscription(address _recipient, Interval _interval) public payable {
        require(_recipient != address(0), "Recipient cannot be the zero address.");
        require(msg.value > 0, "Initial payment amount must be greater than zero.");

        uint256 intervalSeconds = (_interval == Interval.Weekly) ? WEEKLY_INTERVAL : MONTHLY_INTERVAL;

        subscriptions[msg.sender] = Subscription({
            recipient: _recipient,
            amount: msg.value,
            interval: _interval,
            nextPaymentTime: block.timestamp + intervalSeconds,
            isActive: true
        });

        emit SubscriptionSet(msg.sender, _recipient, msg.value, _interval);
    }

    /**
     * @dev Processes a payment for a subscription.
     * Anyone can call this function, but it will only execute if the payment is due.
     * The contract must have sufficient balance to make the payment.
     * @param _subscriber The address of the subscriber whose payment is to be processed.
     */
    function processPayment(address _subscriber) public {
        Subscription storage sub = subscriptions[_subscriber];
        require(sub.isActive, "Subscription is not active.");
        require(block.timestamp >= sub.nextPaymentTime, "Payment is not due yet.");
        require(address(this).balance >= sub.amount, "Contract has insufficient funds to make the payment.");

        sub.nextPaymentTime += (sub.interval == Interval.Weekly) ? WEEKLY_INTERVAL : MONTHLY_INTERVAL;
        
        (bool success, ) = sub.recipient.call{value: sub.amount}("");
        require(success, "Payment transfer failed.");

        emit PaymentMade(_subscriber, sub.recipient, sub.amount);
    }

    /**
     * @dev Allows a user to deposit funds into the contract to cover future payments.
     */
    function deposit() public payable {
        // Any ETH sent to this function is added to the contract balance.
        // It's a general deposit, not tied to a specific subscription's balance.
        // A more advanced contract might track individual balances.
    }

    /**
     * @dev Allows a subscriber to cancel their recurring payment.
     */
    function cancelSubscription() public {
        require(subscriptions[msg.sender].isActive, "No active subscription to cancel.");
        subscriptions[msg.sender].isActive = false;
        emit SubscriptionCancelled(msg.sender);
    }

    /**
     * @dev Returns the details of a user's subscription.
     */
    function getSubscription(address _subscriber) public view returns (address, uint256, Interval, uint256, bool) {
        Subscription storage sub = subscriptions[_subscriber];
        return (sub.recipient, sub.amount, sub.interval, sub.nextPaymentTime, sub.isActive);
    }

    /**
     * @dev Returns the contract's total balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
