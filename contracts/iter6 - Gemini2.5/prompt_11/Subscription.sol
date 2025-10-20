// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    address public owner;
    uint256 public monthlyFee;
    mapping(address => uint256) public subscribers; // Expiration timestamp

    event Subscribed(address indexed user, uint256 expiration);
    event SubscriptionRenewed(address indexed user, uint256 newExpiration);

    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    function subscribe() public payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee.");
        
        uint256 currentExpiration = subscribers[msg.sender];
        uint256 newExpiration;

        if (currentExpiration < block.timestamp) {
            // New or expired subscription
            newExpiration = block.timestamp + 30 days;
            emit Subscribed(msg.sender, newExpiration);
        } else {
            // Renewing an active subscription
            newExpiration = currentExpiration + 30 days;
            emit SubscriptionRenewed(msg.sender, newExpiration);
        }
        
        subscribers[msg.sender] = newExpiration;
    }

    function isSubscribed(address _user) public view returns (bool) {
        return subscribers[_user] >= block.timestamp;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw.");
        payable(owner).transfer(address(this).balance);
    }
}
