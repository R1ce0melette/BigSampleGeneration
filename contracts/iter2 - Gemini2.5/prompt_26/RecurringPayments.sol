// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {
    enum Interval { Weekly, Monthly }

    struct Subscription {
        address payable recipient;
        uint256 amount;
        Interval interval;
        uint256 nextPaymentDate;
        bool active;
    }

    // Mapping from a user to their subscription details
    mapping(address => Subscription) public subscriptions;

    event Subscribed(address indexed user, address indexed recipient, uint256 amount, Interval interval);
    event PaymentMade(address indexed user, address indexed recipient, uint256 amount);
    event Unsubscribed(address indexed user);

    /**
     * @dev Creates or updates a subscription for the message sender.
     * @param _recipient The address to receive the payments.
     * @param _amount The amount for each payment.
     * @param _interval The frequency of payments (Weekly or Monthly).
     */
    function subscribe(address payable _recipient, uint256 _amount, Interval _interval) public {
        require(_recipient != address(0), "Recipient cannot be zero address.");
        require(_amount > 0, "Amount must be greater than zero.");

        uint256 intervalSeconds = _interval == Interval.Weekly ? 7 days : 30 days;

        subscriptions[msg.sender] = Subscription({
            recipient: _recipient,
            amount: _amount,
            interval: _interval,
            nextPaymentDate: block.timestamp + intervalSeconds,
            active: true
        });

        emit Subscribed(msg.sender, _recipient, _amount, _interval);
    }

    /**
     * @dev Processes a payment if the subscription is due. Anyone can trigger this.
     *      The user's wallet must have approved the contract to spend the required amount of a token,
     *      or the user must have deposited funds into the contract. This example uses deposited funds.
     */
    function makePayment(address _user) public {
        Subscription storage sub = subscriptions[_user];
        require(sub.active, "No active subscription for this user.");
        require(block.timestamp >= sub.nextPaymentDate, "Payment not due yet.");
        
        // This contract assumes users deposit ETH into a balance held by the contract.
        // A more complex implementation would use ERC20 tokens and allowances.
        // For simplicity, we'll simulate this with a direct transfer from the contract's balance,
        // assuming the contract is funded appropriately. This is not a secure model for production.
        
        // A real implementation would look like:
        // require(userBalances[_user] >= sub.amount, "Insufficient balance");
        // userBalances[_user] -= sub.amount;
        
        // Simplified for this example:
        require(address(this).balance >= sub.amount, "Contract has insufficient funds.");

        uint256 intervalSeconds = sub.interval == Interval.Weekly ? 7 days : 30 days;
        sub.nextPaymentDate = block.timestamp + intervalSeconds;

        sub.recipient.transfer(sub.amount);
        emit PaymentMade(_user, sub.recipient, sub.amount);
    }

    /**
     * @dev Allows a user to unsubscribe from their recurring payment.
     */
    function unsubscribe() public {
        require(subscriptions[msg.sender].active, "No active subscription to unsubscribe from.");
        subscriptions[msg.sender].active = false;
        emit Unsubscribed(msg.sender);
    }

    /**
     * @dev A function for users to deposit funds to cover their payments.
     */
    function deposit() public payable {
        // In a real contract, you would track each user's balance:
        // userBalances[msg.sender] += msg.value;
    }
}
