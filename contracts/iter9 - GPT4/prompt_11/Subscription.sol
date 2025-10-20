// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    uint256 public constant MONTHLY_FEE = 0.05 ether;
    uint256 public constant PERIOD = 30 days;
    mapping(address => uint256) public subscriptions;

    event Subscribed(address indexed user, uint256 until);

    function subscribe() external payable {
        require(msg.value == MONTHLY_FEE, "Incorrect fee");
        uint256 current = subscriptions[msg.sender];
        if (current < block.timestamp) {
            current = block.timestamp;
        }
        subscriptions[msg.sender] = current + PERIOD;
        emit Subscribed(msg.sender, subscriptions[msg.sender]);
    }

    function isSubscribed(address user) external view returns (bool) {
        return subscriptions[user] >= block.timestamp;
    }

    function subscriptionEnd(address user) external view returns (uint256) {
        return subscriptions[user];
    }
}
