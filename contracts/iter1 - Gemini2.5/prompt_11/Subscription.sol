// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;

    mapping(address => uint256) public subscriptionExpiry;

    event Subscribed(address indexed user, uint256 expiryTime);
    event Withdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(uint256 _subscriptionFee) {
        owner = msg.sender;
        subscriptionFee = _subscriptionFee;
    }

    function subscribe() public payable {
        require(msg.value == subscriptionFee, "Incorrect subscription fee.");

        uint256 currentExpiry = subscriptionExpiry[msg.sender];
        uint256 newExpiry;

        if (currentExpiry < block.timestamp) {
            // If subscription is expired or new
            newExpiry = block.timestamp + SUBSCRIPTION_DURATION;
        } else {
            // If renewing an active subscription
            newExpiry = currentExpiry + SUBSCRIPTION_DURATION;
        }

        subscriptionExpiry[msg.sender] = newExpiry;
        emit Subscribed(msg.sender, newExpiry);
    }

    function isSubscribed(address _user) public view returns (bool) {
        return subscriptionExpiry[_user] >= block.timestamp;
    }

    function getSubscriptionExpiry(address _user) public view returns (uint256) {
        return subscriptionExpiry[_user];
    }

    function setSubscriptionFee(uint256 _newFee) public onlyOwner {
        subscriptionFee = _newFee;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        emit Withdrawn(owner, balance);
        payable(owner).transfer(balance);
    }
}
