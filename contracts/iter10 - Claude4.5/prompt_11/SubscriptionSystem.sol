// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionSystem {
    address public owner;
    uint256 public monthlyFee;

    struct Subscription {
        uint256 startTime;
        uint256 expiryTime;
        bool active;
    }

    mapping(address => Subscription) public subscriptions;

    event Subscribed(address indexed user, uint256 startTime, uint256 expiryTime);
    event SubscriptionRenewed(address indexed user, uint256 newExpiryTime);
    event SubscriptionCancelled(address indexed user);
    event FeeUpdated(uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect payment amount");
        require(!subscriptions[msg.sender].active, "Already have an active subscription");

        uint256 startTime = block.timestamp;
        uint256 expiryTime = startTime + 30 days;

        subscriptions[msg.sender] = Subscription({
            startTime: startTime,
            expiryTime: expiryTime,
            active: true
        });

        emit Subscribed(msg.sender, startTime, expiryTime);
    }

    function renewSubscription() external payable {
        require(msg.value == monthlyFee, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];

        if (sub.active && block.timestamp < sub.expiryTime) {
            // Extend from current expiry
            sub.expiryTime += 30 days;
        } else {
            // Start new subscription
            sub.startTime = block.timestamp;
            sub.expiryTime = block.timestamp + 30 days;
            sub.active = true;
        }

        emit SubscriptionRenewed(msg.sender, sub.expiryTime);
    }

    function cancelSubscription() external {
        require(subscriptions[msg.sender].active, "No active subscription");
        
        subscriptions[msg.sender].active = false;

        emit SubscriptionCancelled(msg.sender);
    }

    function isSubscriptionActive(address user) external view returns (bool) {
        Subscription memory sub = subscriptions[user];
        return sub.active && block.timestamp < sub.expiryTime;
    }

    function getSubscriptionInfo(address user) external view returns (
        uint256 startTime,
        uint256 expiryTime,
        bool active,
        bool isActive
    ) {
        Subscription memory sub = subscriptions[user];
        bool currentlyActive = sub.active && block.timestamp < sub.expiryTime;
        return (sub.startTime, sub.expiryTime, sub.active, currentlyActive);
    }

    function getTimeRemaining(address user) external view returns (uint256) {
        Subscription memory sub = subscriptions[user];
        if (!sub.active || block.timestamp >= sub.expiryTime) {
            return 0;
        }
        return sub.expiryTime - block.timestamp;
    }

    function updateMonthlyFee(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Fee must be greater than 0");
        monthlyFee = newFee;
        emit FeeUpdated(newFee);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner, balance);
    }
}
