// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubscriptionService
 * @dev A contract for a basic subscription service where users pay a monthly fee in ETH for access.
 */
contract SubscriptionService {
    // The owner of the contract who receives the subscription fees.
    address public owner;

    // The monthly subscription fee in wei.
    uint256 public monthlyFee;

    // Mapping from user address to the timestamp when their subscription expires.
    mapping(address => uint256) public subscriptions;

    /**
     * @dev Emitted when a user subscribes or renews their subscription.
     * @param user The address of the subscriber.
     * @param expirationTimestamp The new expiration timestamp of the subscription.
     */
    event Subscribed(address indexed user, uint256 expirationTimestamp);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "SubscriptionService: Caller is not the owner.");
        _;
    }

    /**
     * @dev Sets up the contract with the owner and the monthly subscription fee.
     * @param _monthlyFeeInEth The monthly subscription fee in ETH.
     */
    constructor(uint256 _monthlyFeeInEth) {
        owner = msg.sender;
        monthlyFee = _monthlyFeeInEth * 1 ether; // Convert ETH to wei
    }

    /**
     * @dev Allows a user to subscribe or renew their subscription by paying the monthly fee.
     */
    function subscribe() public payable {
        require(msg.value == monthlyFee, "SubscriptionService: Incorrect subscription fee paid.");

        uint256 currentExpiration = subscriptions[msg.sender];
        uint256 newExpiration;

        // If the user is already subscribed and their subscription is still active, extend it.
        // Otherwise, start a new subscription from the current time.
        if (currentExpiration > block.timestamp) {
            newExpiration = currentExpiration + 30 days;
        } else {
            newExpiration = block.timestamp + 30 days;
        }

        subscriptions[msg.sender] = newExpiration;

        emit Subscribed(msg.sender, newExpiration);
    }

    /**
     * @dev Checks if a user's subscription is currently active.
     * @param user The address of the user to check.
     * @return True if the subscription is active, false otherwise.
     */
    function isSubscribed(address user) public view returns (bool) {
        return subscriptions[user] > block.timestamp;
    }

    /**
     * @dev Allows the owner to change the monthly subscription fee.
     * @param _newMonthlyFeeInEth The new monthly fee in ETH.
     */
    function setMonthlyFee(uint256 _newMonthlyFeeInEth) public onlyOwner {
        monthlyFee = _newMonthlyFeeInEth * 1 ether;
    }

    /**
     * @dev Allows the owner to withdraw the collected subscription fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "SubscriptionService: No fees to withdraw.");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "SubscriptionService: Withdrawal failed.");
    }
}
