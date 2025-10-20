// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionService is Ownable {
    uint256 public monthlyFee;
    mapping(address => uint256) public subscriptionEnd;

    event Subscribed(address indexed user, uint256 endDate);
    event FeeUpdated(uint256 newFee);

    constructor(uint256 _initialFee) Ownable(msg.sender) {
        monthlyFee = _initialFee;
    }

    /**
     * @dev Allows a user to subscribe by paying the monthly fee.
     */
    function subscribe() public payable {
        require(msg.value == monthlyFee, "Incorrect subscription fee paid.");
        
        uint256 currentSubscriptionEnd = subscriptionEnd[msg.sender];
        uint256 newEndDate;

        if (currentSubscriptionEnd < block.timestamp) {
            // If subscription is expired or new, start from now
            newEndDate = block.timestamp + 30 days;
        } else {
            // If renewing, extend from the current end date
            newEndDate = currentSubscriptionEnd + 30 days;
        }

        subscriptionEnd[msg.sender] = newEndDate;
        emit Subscribed(msg.sender, newEndDate);
    }

    /**
     * @dev Checks if a user's subscription is currently active.
     * @param _user The address of the user to check.
     * @return True if the subscription is active, false otherwise.
     */
    function isSubscribed(address _user) public view returns (bool) {
        return subscriptionEnd[_user] >= block.timestamp;
    }

    /**
     * @dev Allows the owner to update the monthly subscription fee.
     * @param _newFee The new fee for the subscription.
     */
    function setMonthlyFee(uint256 _newFee) public onlyOwner {
        require(_newFee > 0, "Fee must be greater than zero.");
        monthlyFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    /**
     * @dev Allows the owner to withdraw the collected fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");
        payable(owner()).transfer(balance);
    }
}
