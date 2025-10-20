// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubscriptionService
 * @dev A contract for a basic subscription service where users pay a monthly fee in ETH for access.
 */
contract SubscriptionService {
    address public owner;
    uint256 public monthlyFee;
    mapping(address => uint256) public subscriptions;

    event Subscribed(address indexed user, uint256 expirationTimestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor(uint256 _monthlyFeeInEth) {
        owner = msg.sender;
        monthlyFee = _monthlyFeeInEth * 1 ether;
    }

    /**
     * @dev Allows a user to subscribe or renew their subscription by paying the monthly fee.
     */
    function subscribe() public payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee paid.");

        uint256 currentExpiration = subscriptions[msg.sender];
        uint256 newExpiration;

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
        require(balance > 0, "No fees to withdraw.");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed.");
    }
}
