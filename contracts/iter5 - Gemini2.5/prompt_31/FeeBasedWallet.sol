// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeeBasedWallet
 * @dev A wallet that charges a 1% fee on withdrawals, paid to the owner.
 */
contract FeeBasedWallet {

    address public owner;
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Deposits ETH into the user's balance.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be positive.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Withdraws ETH from the user's balance, with a 1% fee.
     */
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        
        uint256 fee = _amount / 100;
        uint256 amountToWithdraw = _amount - fee;

        balances[msg.sender] -= _amount;

        payable(msg.sender).transfer(amountToWithdraw);
        payable(owner).transfer(fee);

        emit Withdrawn(msg.sender, amountToWithdraw, fee);
    }
}
