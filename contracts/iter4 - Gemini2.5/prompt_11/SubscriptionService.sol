// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionService {
    address public owner;
    uint256 public monthlyFee;
    mapping(address => uint256) public subscriptionEnd;

    event Subscribed(address indexed user, uint256 endTime);
    event Renewed(address indexed user, uint256 endTime);
    event FeeWithdrawn(address indexed owner, uint256 amount);

    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    function subscribe() public payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee paid.");
        require(subscriptionEnd[msg.sender] < block.timestamp, "You are already subscribed.");

        subscriptionEnd[msg.sender] = block.timestamp + 30 days;
        emit Subscribed(msg.sender, subscriptionEnd[msg.sender]);
    }

    function renew() public payable {
        require(msg.value == monthlyFee, "Incorrect renewal fee paid.");
        require(subscriptionEnd[msg.sender] >= block.timestamp, "Your subscription has expired, please subscribe again.");

        subscriptionEnd[msg.sender] += 30 days;
        emit Renewed(msg.sender, subscriptionEnd[msg.sender]);
    }

    function isSubscribed(address _user) public view returns (bool) {
        return subscriptionEnd[_user] >= block.timestamp;
    }

    function withdrawFees() public {
        require(msg.sender == owner, "Only the owner can withdraw fees.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");
        
        emit FeeWithdrawn(owner, balance);
        payable(owner).transfer(balance);
    }
    
    function getSubscriptionEndTime(address _user) public view returns (uint256) {
        return subscriptionEnd[_user];
    }
}
