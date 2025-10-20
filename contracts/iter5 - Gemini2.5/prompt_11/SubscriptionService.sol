// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubscriptionService
 * @dev A contract for a basic monthly subscription service using ETH.
 */
contract SubscriptionService {
    // Address of the service owner who receives the subscription fees.
    address public owner;
    // The monthly subscription fee in wei.
    uint256 public monthlyFee;
    // The duration of a subscription period in seconds (30 days).
    uint256 public constant SUBSCRIPTION_PERIOD = 30 days;

    // Mapping from a user's address to the timestamp when their subscription expires.
    mapping(address => uint256) public subscriptionExpiresAt;

    /**
     * @dev Event emitted when a user subscribes or renews their subscription.
     * @param user The address of the subscriber.
     * @param expirationTimestamp The new expiration timestamp of the subscription.
     */
    event Subscribed(address indexed user, uint256 expirationTimestamp);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the owner and the monthly subscription fee upon deployment.
     * @param _monthlyFee The fee for a one-month subscription, in wei.
     */
    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    /**
     * @dev Allows a user to subscribe or renew their subscription.
     * The user must send the exact monthly fee in ETH.
     */
    function subscribe() public payable {
        require(msg.value == monthlyFee, "Payment must be equal to the monthly fee.");

        uint256 currentExpiration = subscriptionExpiresAt[msg.sender];
        uint256 newExpiration;

        // If the user is already subscribed and their subscription is active,
        // extend it from the current expiration date. Otherwise, start a new subscription.
        if (currentExpiration > block.timestamp) {
            newExpiration = currentExpiration + SUBSCRIPTION_PERIOD;
        } else {
            newExpiration = block.timestamp + SUBSCRIPTION_PERIOD;
        }

        subscriptionExpiresAt[msg.sender] = newExpiration;
        emit Subscribed(msg.sender, newExpiration);
    }

    /**
     * @dev Checks if a user's subscription is currently active.
     * @param _user The address of the user to check.
     * @return A boolean indicating whether the subscription is active.
     */
    function isSubscribed(address _user) public view returns (bool) {
        return subscriptionExpiresAt[_user] > block.timestamp;
    }

    /**
     * @dev Allows the owner to withdraw the collected fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");

        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Failed to withdraw fees.");
    }

    /**
     * @dev Allows the owner to update the monthly subscription fee.
     * @param _newFee The new monthly fee in wei.
     */
    function setMonthlyFee(uint256 _newFee) public onlyOwner {
        require(_newFee > 0, "Monthly fee must be positive.");
        monthlyFee = _newFee;
    }

    /**
     * @dev Retrieves the subscription expiration timestamp for a user.
     * @param _user The address of the user.
     * @return The timestamp when the user's subscription expires.
     */
    function getSubscriptionExpiration(address _user) public view returns (uint256) {
        return subscriptionExpiresAt[_user];
    }
}
