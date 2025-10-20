// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {

    struct PaymentPlan {
        uint256 id;
        address payable payer;
        address payable payee;
        uint256 amount;
        uint256 interval; // in seconds (e.g., 7 days, 30 days)
        uint256 nextPaymentTimestamp;
        bool isActive;
    }

    mapping(uint256 => PaymentPlan) public paymentPlans;
    uint256 public planCounter;

    // Balances deposited by payers
    mapping(address => uint256) public balances;

    event PlanCreated(uint256 indexed planId, address indexed payer, address indexed payee, uint256 amount, uint256 interval);
    event PlanCancelled(uint256 indexed planId);
    event PaymentMade(uint256 indexed planId, uint256 amount, uint256 timestamp);
    event FundsDeposited(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // Payer deposits funds into the contract to be used for future payments
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be positive.");
        balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Payer can withdraw their unused balance
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    // Payer authorizes a new recurring payment plan
    function authorizePayment(address payable _payee, uint256 _amount, uint256 _intervalInSeconds) public {
        require(_payee != address(0), "Payee cannot be the zero address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_intervalInSeconds > 0, "Interval must be greater than zero.");

        planCounter++;
        paymentPlans[planCounter] = PaymentPlan({
            id: planCounter,
            payer: payable(msg.sender),
            payee: _payee,
            amount: _amount,
            interval: _intervalInSeconds,
            nextPaymentTimestamp: block.timestamp + _intervalInSeconds,
            isActive: true
        });

        emit PlanCreated(planCounter, msg.sender, _payee, _amount, _intervalInSeconds);
    }

    // Anyone (usually the payee) can trigger an authorized payment if it's due
    function executePayment(uint256 _planId) public {
        PaymentPlan storage plan = paymentPlans[_planId];

        require(plan.isActive, "Payment plan is not active.");
        require(block.timestamp >= plan.nextPaymentTimestamp, "Payment is not due yet.");
        require(balances[plan.payer] >= plan.amount, "Payer has insufficient balance.");

        // Update payer's balance and transfer funds to payee
        balances[plan.payer] -= plan.amount;
        plan.payee.transfer(plan.amount);

        // Set the next payment time
        plan.nextPaymentTimestamp = block.timestamp + plan.interval;

        emit PaymentMade(_planId, plan.amount, block.timestamp);
    }

    // Payer can cancel their payment plan
    function cancelPlan(uint256 _planId) public {
        PaymentPlan storage plan = paymentPlans[_planId];
        require(plan.payer == msg.sender, "Only the payer can cancel the plan.");
        require(plan.isActive, "Plan is already inactive.");

        plan.isActive = false;
        emit PlanCancelled(_planId);
    }
}
