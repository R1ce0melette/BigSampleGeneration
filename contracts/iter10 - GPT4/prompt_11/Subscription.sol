// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    uint256 public constant MONTHLY_FEE = 0.05 ether;
    uint256 public constant PERIOD = 30 days;
    mapping(address => uint256) public subscriptions;
    address public owner;

    event Subscribed(address indexed user, uint256 until);
    event Withdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function subscribe() external payable {
        require(msg.value == MONTHLY_FEE, "Incorrect fee");
        if (subscriptions[msg.sender] < block.timestamp) {
            subscriptions[msg.sender] = block.timestamp + PERIOD;
        } else {
            subscriptions[msg.sender] += PERIOD;
        }
        emit Subscribed(msg.sender, subscriptions[msg.sender]);
    }

    function isSubscribed(address user) external view returns (bool) {
        return subscriptions[user] >= block.timestamp;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds");
        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }
}
