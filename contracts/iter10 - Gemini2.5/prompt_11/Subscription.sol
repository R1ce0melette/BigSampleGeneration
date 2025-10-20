// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    address public owner;
    uint256 public monthlyFee;
    mapping(address => uint256) public subscribers; // Maps user to their subscription end time

    event Subscribed(address indexed user, uint256 endTime);
    event Renewed(address indexed user, uint256 endTime);
    event Canceled(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(uint256 _monthlyFee) {
        owner = msg.sender;
        monthlyFee = _monthlyFee;
    }

    function subscribe() public payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee.");
        require(subscribers[msg.sender] < block.timestamp, "You are already subscribed.");

        subscribers[msg.sender] = block.timestamp + 30 days;
        emit Subscribed(msg.sender, subscribers[msg.sender]);
    }

    function renew() public payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee.");
        require(subscribers[msg.sender] >= block.timestamp, "Your subscription has expired, please subscribe again.");

        subscribers[msg.sender] += 30 days;
        emit Renewed(msg.sender, subscribers[msg.sender]);
    }

    function cancelSubscription() public {
        require(subscribers[msg.sender] > 0, "You are not subscribed.");
        delete subscribers[msg.sender];
        emit Canceled(msg.sender);
    }

    function isSubscribed(address _user) public view returns (bool) {
        return subscribers[_user] >= block.timestamp;
    }

    function getSubscriptionEndTime(address _user) public view returns (uint256) {
        return subscribers[_user];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
