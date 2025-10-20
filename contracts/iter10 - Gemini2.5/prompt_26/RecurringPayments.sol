// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {
    struct PaymentPlan {
        address payable recipient;
        uint256 amount;
        uint256 interval; // in seconds (e.g., 7 days for weekly, 30 days for monthly)
        uint256 nextPaymentTime;
    }

    mapping(address => PaymentPlan) public paymentPlans;

    event PlanCreated(address indexed user, address indexed recipient, uint256 amount, uint256 interval);
    event PaymentMade(address indexed user, address indexed recipient, uint256 amount);
    event PlanCanceled(address indexed user);

    function createPlan(address payable _recipient, uint256 _amount, uint256 _intervalInDays) public {
        require(_recipient != address(0), "Recipient cannot be the zero address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_intervalInDays > 0, "Interval must be greater than zero.");
        require(paymentPlans[msg.sender].recipient == address(0), "A payment plan already exists for this user.");

        uint256 intervalInSeconds = _intervalInDays * 1 days;
        paymentPlans[msg.sender] = PaymentPlan({
            recipient: _recipient,
            amount: _amount,
            interval: intervalInSeconds,
            nextPaymentTime: block.timestamp + intervalInSeconds
        });

        emit PlanCreated(msg.sender, _recipient, _amount, intervalInSeconds);
    }

    function makePayment() public {
        PaymentPlan storage plan = paymentPlans[msg.sender];
        require(plan.recipient != address(0), "No payment plan found.");
        require(block.timestamp >= plan.nextPaymentTime, "It's not time for the next payment yet.");
        require(address(this).balance >= plan.amount, "Contract does not have enough funds to make the payment.");

        plan.nextPaymentTime += plan.interval;
        plan.recipient.transfer(plan.amount);

        emit PaymentMade(msg.sender, plan.recipient, plan.amount);
    }

    function cancelPlan() public {
        require(paymentPlans[msg.sender].recipient != address(0), "No payment plan to cancel.");
        delete paymentPlans[msg.sender];
        emit PlanCanceled(msg.sender);
    }

    function fundContract() public payable {
        // Users can send ETH to the contract to fund their payments
    }

    function getPlanDetails() public view returns (address, uint256, uint256, uint256) {
        PaymentPlan storage plan = paymentPlans[msg.sender];
        return (plan.recipient, plan.amount, plan.interval, plan.nextPaymentTime);
    }
}
