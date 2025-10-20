// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {

    struct PaymentPlan {
        address payable payer;
        address payable payee;
        uint256 amount;
        uint256 interval; // in seconds (e.g., 7 days for weekly, 30 days for monthly)
        uint256 nextPaymentTimestamp;
        bool isActive;
    }

    // Mapping from a payer to their payment plan. One plan per payer for simplicity.
    mapping(address => PaymentPlan) public paymentPlans;
    // Mapping to store deposited funds for each payer.
    mapping(address => uint256) public balances;

    uint256 public constant WEEKLY = 7 days;
    uint256 public constant MONTHLY = 30 days;

    event PlanCreated(address indexed payer, address indexed payee, uint256 amount, uint256 interval);
    event PlanCancelled(address indexed payer);
    event PaymentMade(address indexed payer, address indexed payee, uint256 amount);
    event Deposit(address indexed payer, uint256 amount);
    event Withdrawal(address indexed payer, uint256 amount);

    function createPaymentPlan(address payable _payee, uint256 _amount, uint256 _interval) public {
        require(!paymentPlans[msg.sender].isActive, "A payment plan already exists for this address.");
        require(_payee != address(0), "Payee cannot be the zero address.");
        require(_amount > 0, "Payment amount must be greater than zero.");
        require(_interval == WEEKLY || _interval == MONTHLY, "Invalid payment interval.");

        paymentPlans[msg.sender] = PaymentPlan({
            payer: payable(msg.sender),
            payee: _payee,
            amount: _amount,
            interval: _interval,
            nextPaymentTimestamp: block.timestamp + _interval,
            isActive: true
        });

        emit PlanCreated(msg.sender, _payee, _amount, _interval);
    }

    function deposit() public payable {
        require(paymentPlans[msg.sender].isActive, "No active payment plan found.");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function executePayment(address _payer) public {
        PaymentPlan storage plan = paymentPlans[_payer];
        require(plan.isActive, "No active payment plan for this payer.");
        require(block.timestamp >= plan.nextPaymentTimestamp, "Payment is not due yet.");
        require(balances[_payer] >= plan.amount, "Insufficient balance for this payment.");

        balances[_payer] -= plan.amount;
        plan.nextPaymentTimestamp += plan.interval;

        plan.payee.transfer(plan.amount);

        emit PaymentMade(_payer, plan.payee, plan.amount);
    }

    function cancelPaymentPlan() public {
        PaymentPlan storage plan = paymentPlans[msg.sender];
        require(plan.isActive, "No active payment plan to cancel.");

        plan.isActive = false;
        uint256 remainingBalance = balances[msg.sender];
        
        if (remainingBalance > 0) {
            balances[msg.sender] = 0;
            payable(msg.sender).transfer(remainingBalance);
            emit Withdrawal(msg.sender, remainingBalance);
        }

        emit PlanCancelled(msg.sender);
    }

    function getPlanDetails(address _payer) public view returns (address, address, uint256, uint256, uint256, bool) {
        PaymentPlan storage plan = paymentPlans[_payer];
        return (plan.payer, plan.payee, plan.amount, plan.interval, plan.nextPaymentTimestamp, plan.isActive);
    }
}
