// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubscriptionManager
 * @dev A contract for a basic subscription system where users pay a monthly fee in ETH.
 */
contract SubscriptionManager {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public constant MONTH_IN_SECONDS = 30 days;

    mapping(address => uint256) public subscriptionEndTimes;

    /**
     * @dev Emitted when a user subscribes or renews their subscription.
     * @param user The address of the subscriber.
     * @param newEndTime The new expiration timestamp of the subscription.
     */
    event Subscribed(address indexed user, uint256 newEndTime);

    /**
     * @dev Emitted when the subscription fee is updated by the owner.
     * @param newFee The new subscription fee in wei.
     */
    event SubscriptionFeeUpdated(uint256 newFee);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets up the contract with an initial subscription fee.
     * @param _initialFee The initial monthly subscription fee in wei.
     */
    constructor(uint256 _initialFee) {
        require(_initialFee > 0, "Initial fee must be greater than zero.");
        owner = msg.sender;
        subscriptionFee = _initialFee;
    }

    /**
     * @dev Allows a user to subscribe or renew their subscription by paying the fee.
     */
    function subscribe() public payable {
        require(msg.value == subscriptionFee, "Incorrect subscription fee paid.");

        uint256 currentEndTime = subscriptionEndTimes[msg.sender];
        uint256 newEndTime;

        // If the user has an active subscription, extend it. Otherwise, start a new one.
        if (currentEndTime > block.timestamp) {
            newEndTime = currentEndTime + MONTH_IN_SECONDS;
        } else {
            newEndTime = block.timestamp + MONTH_IN_SECONDS;
        }

        subscriptionEndTimes[msg.sender] = newEndTime;
        emit Subscribed(msg.sender, newEndTime);
    }

    /**
     * @dev Checks if a user's subscription is currently active.
     * @param _user The address of the user to check.
     * @return True if the subscription is active, false otherwise.
     */
    function isSubscribed(address _user) public view returns (bool) {
        return subscriptionEndTimes[_user] > block.timestamp;
    }

    /**
     * @dev Allows the owner to update the subscription fee.
     * @param _newFee The new monthly subscription fee in wei.
     */
    function setSubscriptionFee(uint256 _newFee) public onlyOwner {
        require(_newFee > 0, "New fee must be greater than zero.");
        subscriptionFee = _newFee;
        emit SubscriptionFeeUpdated(_newFee);
    }

    /**
     * @dev Allows the owner to withdraw the collected fees from the contract.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Returns the current balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
