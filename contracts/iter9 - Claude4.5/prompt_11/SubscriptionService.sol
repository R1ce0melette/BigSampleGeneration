// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionService {
    address public owner;
    uint256 public monthlyFee;
    
    struct Subscription {
        uint256 startTimestamp;
        uint256 expirationTimestamp;
        bool active;
    }
    
    mapping(address => Subscription) public subscriptions;
    
    // Events
    event Subscribed(address indexed user, uint256 expirationTimestamp);
    event SubscriptionRenewed(address indexed user, uint256 newExpirationTimestamp);
    event SubscriptionCancelled(address indexed user);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the subscription service
     * @param _monthlyFee The monthly subscription fee in wei
     */
    constructor(uint256 _monthlyFee) {
        require(_monthlyFee > 0, "Monthly fee must be greater than 0");
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }
    
    /**
     * @dev Subscribe to the service for one month
     */
    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect payment amount");
        require(!isSubscriptionActive(msg.sender), "Subscription already active");
        
        uint256 expirationTimestamp = block.timestamp + 30 days;
        
        subscriptions[msg.sender] = Subscription({
            startTimestamp: block.timestamp,
            expirationTimestamp: expirationTimestamp,
            active: true
        });
        
        emit Subscribed(msg.sender, expirationTimestamp);
    }
    
    /**
     * @dev Renew an existing subscription for another month
     */
    function renewSubscription() external payable {
        require(msg.value == monthlyFee, "Incorrect payment amount");
        
        Subscription storage sub = subscriptions[msg.sender];
        
        uint256 newExpirationTimestamp;
        
        // If subscription is still active, extend from current expiration
        if (isSubscriptionActive(msg.sender)) {
            newExpirationTimestamp = sub.expirationTimestamp + 30 days;
        } else {
            // If expired, start new subscription from now
            newExpirationTimestamp = block.timestamp + 30 days;
            sub.startTimestamp = block.timestamp;
            sub.active = true;
        }
        
        sub.expirationTimestamp = newExpirationTimestamp;
        
        emit SubscriptionRenewed(msg.sender, newExpirationTimestamp);
    }
    
    /**
     * @dev Cancel an active subscription (no refund)
     */
    function cancelSubscription() external {
        require(subscriptions[msg.sender].active, "No active subscription");
        
        subscriptions[msg.sender].active = false;
        
        emit SubscriptionCancelled(msg.sender);
    }
    
    /**
     * @dev Check if a user has an active subscription
     * @param _user The address of the user
     * @return True if subscription is active, false otherwise
     */
    function isSubscriptionActive(address _user) public view returns (bool) {
        Subscription memory sub = subscriptions[_user];
        return sub.active && block.timestamp < sub.expirationTimestamp;
    }
    
    /**
     * @dev Get subscription details for a user
     * @param _user The address of the user
     * @return startTimestamp The subscription start timestamp
     * @return expirationTimestamp The subscription expiration timestamp
     * @return active Whether the subscription is marked as active
     * @return isCurrentlyActive Whether the subscription is currently active (including time check)
     */
    function getSubscriptionDetails(address _user) external view returns (
        uint256 startTimestamp,
        uint256 expirationTimestamp,
        bool active,
        bool isCurrentlyActive
    ) {
        Subscription memory sub = subscriptions[_user];
        
        return (
            sub.startTimestamp,
            sub.expirationTimestamp,
            sub.active,
            isSubscriptionActive(_user)
        );
    }
    
    /**
     * @dev Get remaining time for a subscription
     * @param _user The address of the user
     * @return The remaining time in seconds (0 if expired)
     */
    function getRemainingTime(address _user) external view returns (uint256) {
        if (!isSubscriptionActive(_user)) {
            return 0;
        }
        
        return subscriptions[_user].expirationTimestamp - block.timestamp;
    }
    
    /**
     * @dev Update the monthly subscription fee
     * @param _newFee The new monthly fee in wei
     */
    function updateMonthlyFee(uint256 _newFee) external onlyOwner {
        require(_newFee > 0, "Fee must be greater than 0");
        
        uint256 oldFee = monthlyFee;
        monthlyFee = _newFee;
        
        emit FeeUpdated(oldFee, _newFee);
    }
    
    /**
     * @dev Withdraw collected fees
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, balance);
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
