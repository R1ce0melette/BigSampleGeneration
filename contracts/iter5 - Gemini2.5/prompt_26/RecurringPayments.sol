// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RecurringPayments
 * @dev A contract for setting up recurring weekly or monthly payments.
 */
contract RecurringPayments {

    enum Interval { Weekly, Monthly }

    struct PaymentPlan {
        address payable recipient;
        uint256 amount;
        Interval interval;
        uint256 nextPayment;
    }

    mapping(address => PaymentPlan) public paymentPlans;
    address public owner;

    event PlanCreated(address indexed from, address indexed to, uint256 amount, Interval interval);
    event PaymentMade(address indexed from, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Creates a new recurring payment plan.
     */
    function createPlan(address payable _recipient, uint256 _amount, Interval _interval) public {
        require(_recipient != address(0), "Recipient cannot be zero address.");
        require(_amount > 0, "Amount must be greater than zero.");
        
        uint256 intervalSeconds = _interval == Interval.Weekly ? 7 days : 30 days;
        
        paymentPlans[msg.sender] = PaymentPlan({
            recipient: _recipient,
            amount: _amount,
            interval: _interval,
            nextPayment: block.timestamp + intervalSeconds
        });
        
        emit PlanCreated(msg.sender, _recipient, _amount, _interval);
    }

    /**
     * @dev Executes a payment if it's due.
     */
    function executePayment() public {
        PaymentPlan storage plan = paymentPlans[msg.sender];
        require(plan.recipient != address(0), "No payment plan found.");
        require(block.timestamp >= plan.nextPayment, "Payment not due yet.");
        
        uint256 intervalSeconds = plan.interval == Interval.Weekly ? 7 days : 30 days;
        plan.nextPayment += intervalSeconds;
        
        payable(plan.recipient).transfer(plan.amount);
        emit PaymentMade(msg.sender, plan.recipient, plan.amount);
    }

    /**
     * @dev Cancels an existing payment plan.
     */
    function cancelPlan() public {
        require(paymentPlans[msg.sender].recipient != address(0), "No payment plan to cancel.");
        delete paymentPlans[msg.sender];
    }
}
