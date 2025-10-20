// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subscription {
    address public owner;
    uint256 public monthlyFee;
    mapping(address => uint256) public subscribers;

    event Subscribed(address indexed user, uint256 expiration);
    event Unsubscribed(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

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
        } else {
            // Extend existing subscription
            newExpiration = currentExpiration + 30 days;
        }
        
        subscribers[msg.sender] = newExpiration;
        emit Subscribed(msg.sender, newExpiration);
    }

    function unsubscribe() public {
        require(subscribers[msg.sender] > 0, "Not subscribed.");
        delete subscribers[msg.sender];
        emit Unsubscribed(msg.sender);
    }

    function isSubscribed(address _user) public view returns (bool) {
        return subscribers[_user] >= block.timestamp;
    }

    function getSubscriptionExpiration(address _user) public view returns (uint256) {
        return subscribers[_user];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function setMonthlyFee(uint256 _newFee) public onlyOwner {
        monthlyFee = _newFee;
    }
}
