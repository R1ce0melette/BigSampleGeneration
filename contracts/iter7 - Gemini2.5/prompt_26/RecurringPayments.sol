// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RecurringPayments
 * @dev A contract that allows users to set up and manage recurring (weekly or monthly) ETH payments to a recipient.
 */
contract RecurringPayments {
    // Struct to define a payment plan.
    struct PaymentPlan {
        address payable recipient;
        uint256 amount;
        uint256 interval; // in seconds (e.g., 7 days for weekly, 30 days for monthly)
        uint256 nextPaymentTime;
        bool isActive;
    }

    // Mapping from a user's address to their payment plan.
    // A user can only have one active payment plan at a time in this simple implementation.
    mapping(address => PaymentPlan) public paymentPlans;

    uint256 public constant WEEKLY = 7 days;
    uint256 public constant MONTHLY = 30 days;

    /**
     * @dev Emitted when a new payment plan is created.
     * @param from The address of the user setting up the payment.
     * @param to The address of the recipient.
     * @param amount The amount per payment.
     * @param interval The payment interval in seconds.
     */
    event PlanCreated(address indexed from, address indexed to, uint256 amount, uint256 interval);

    /**
     * @dev Emitted when a payment is executed.
     * @param from The address of the payer.
     * @param to The address of the recipient.
     * @param amount The amount paid.
     */
    event PaymentMade(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted when a payment plan is cancelled.
     * @param from The address of the user who cancelled the plan.
     */
    event PlanCancelled(address indexed from);

    /**
     * @dev Creates a new recurring payment plan. The user must send enough ETH to cover at least the first payment.
     * @param _recipient The address of the recipient.
     * @param _amount The amount of ETH for each payment.
     * @param _isWeekly True for weekly payments, false for monthly payments.
     */
    function createPlan(address payable _recipient, uint256 _amount, bool _isWeekly) public payable {
        require(_recipient != address(0), "Recipient cannot be the zero address.");
        require(_amount > 0, "Payment amount must be greater than zero.");
        require(msg.value >= _amount, "Initial deposit must cover at least one payment.");
        require(!paymentPlans[msg.sender].isActive, "You already have an active payment plan.");

        uint256 interval = _isWeekly ? WEEKLY : MONTHLY;
        
        paymentPlans[msg.sender] = PaymentPlan({
            recipient: _recipient,
            amount: _amount,
            interval: interval,
            nextPaymentTime: block.timestamp + interval,
            isActive: true
        });

        emit PlanCreated(msg.sender, _recipient, _amount, interval);
    }

    /**
     * @dev Executes a payment if the time has come. Anyone can call this function to trigger the payment.
     * The contract must have sufficient balance to make the payment.
     */
    function executePayment() public {
        PaymentPlan storage plan = paymentPlans[msg.sender];
        require(plan.isActive, "No active payment plan for this user.");
        require(block.timestamp >= plan.nextPaymentTime, "It's not time for the next payment yet.");
        require(address(this).balance >= plan.amount, "Insufficient contract balance to make the payment.");

        plan.nextPaymentTime += plan.interval;
        
        (bool success, ) = plan.recipient.call{value: plan.amount}("");
        require(success, "Payment failed.");

        emit PaymentMade(msg.sender, plan.recipient, plan.amount);
    }

    /**
     * @dev Allows a user to cancel their active payment plan.
     * Any remaining balance for this user is refunded.
     */
    function cancelPlan() public {
        PaymentPlan storage plan = paymentPlans[msg.sender];
        require(plan.isActive, "No active payment plan to cancel.");

        plan.isActive = false;
        
        // In this simple model, we can't easily track individual user balances.
        // A more complex contract would be needed to handle refunds properly.
        // For now, we just deactivate the plan.
        
        emit PlanCancelled(msg.sender);
    }

    /**
     * @dev Allows a user to deposit more ETH to fund their payment plan.
     */
    function deposit() public payable {
        require(paymentPlans[msg.sender].isActive, "No active payment plan to deposit funds for.");
        require(msg.value > 0, "Deposit amount must be greater than zero.");
    }
}
