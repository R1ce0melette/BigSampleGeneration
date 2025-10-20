// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecurringPayments {
    enum Period { Weekly, Monthly }

    struct Payment {
        address payer;
        address payable payee;
        uint256 amount;
        Period period;
        uint256 nextPayment;
        bool active;
    }

    mapping(address => Payment[]) public payments;

    event PaymentAuthorized(address indexed payer, address indexed payee, uint256 amount, Period period);
    event PaymentExecuted(address indexed payer, address indexed payee, uint256 amount);
    event PaymentCancelled(address indexed payer, uint256 index);

    function authorizePayment(address payable payee, uint256 amount, Period period) external payable {
        require(amount > 0, "Amount must be positive");
        uint256 interval = period == Period.Weekly ? 7 days : 30 days;
        payments[msg.sender].push(Payment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            period: period,
            nextPayment: block.timestamp + interval,
            active: true
        }));
        emit PaymentAuthorized(msg.sender, payee, amount, period);
    }

    function executePayment(address payer, uint256 index) external {
        Payment storage p = payments[payer][index];
        require(p.active, "Not active");
        require(block.timestamp >= p.nextPayment, "Too early");
        require(address(this).balance >= p.amount, "Insufficient contract balance");
        p.nextPayment += p.period == Period.Weekly ? 7 days : 30 days;
        (bool sent, ) = p.payee.call{value: p.amount}("");
        require(sent, "Transfer failed");
        emit PaymentExecuted(payer, p.payee, p.amount);
    }

    function cancelPayment(uint256 index) external {
        Payment storage p = payments[msg.sender][index];
        require(p.active, "Not active");
        p.active = false;
        emit PaymentCancelled(msg.sender, index);
    }

    // Allow users to deposit ETH to the contract
    receive() external payable {}
}
