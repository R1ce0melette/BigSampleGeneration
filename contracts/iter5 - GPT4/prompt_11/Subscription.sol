// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    uint256 public monthlyFee;
    mapping(address => uint256) public subscriptions;

    event Subscribed(address indexed user, uint256 until);

    constructor(uint256 _monthlyFee) {
        monthlyFee = _monthlyFee;
    }

    function subscribe() external payable {
        require(msg.value == monthlyFee, "Incorrect fee");
        if (subscriptions[msg.sender] < block.timestamp) {
            subscriptions[msg.sender] = block.timestamp + 30 days;
        } else {
            subscriptions[msg.sender] += 30 days;
        }
        emit Subscribed(msg.sender, subscriptions[msg.sender]);
    }

    function isSubscribed(address user) external view returns (bool) {
        return subscriptions[user] >= block.timestamp;
    }

    function subscriptionEnds(address user) external view returns (uint256) {
        return subscriptions[user];
    }
}
