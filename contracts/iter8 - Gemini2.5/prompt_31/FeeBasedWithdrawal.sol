// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeeBasedWithdrawal
 * @dev A contract where users can deposit ETH and withdraw it later,
 * with a 1% fee on withdrawal paid to the contract owner.
 */
contract FeeBasedWithdrawal {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public constant WITHDRAWAL_FEE_PERCENT = 1;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows a user to deposit ETH into the contract.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw their entire balance, minus a 1% fee.
     */
    function withdraw() external {
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "You have no balance to withdraw.");

        uint256 fee = (userBalance * WITHDRAWAL_FEE_PERCENT) / 100;
        uint256 amountToWithdraw = userBalance - fee;

        balances[msg.sender] = 0;

        // Transfer the user's portion
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");

        // Transfer the fee to the owner
        if (fee > 0) {
            (bool feeSuccess, ) = payable(owner).call{value: fee}("");
            require(feeSuccess, "Fee transfer failed.");
        }

        emit Withdrawn(msg.sender, amountToWithdraw, fee);
    }

    /**
     * @dev Allows a user to withdraw a specific amount, minus a 1% fee.
     * @param _amount The amount the user wishes to withdraw from their balance.
     */
    function withdrawAmount(uint256 _amount) external {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        uint256 fee = (_amount * WITHDRAWAL_FEE_PERCENT) / 100;
        uint256 amountToWithdraw = _amount - fee;

        balances[msg.sender] -= _amount;

        // Transfer the user's portion
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");

        // Transfer the fee to the owner
        if (fee > 0) {
            (bool feeSuccess, ) = payable(owner).call{value: fee}("");
            require(feeSuccess, "Fee transfer failed.");
        }

        emit Withdrawn(msg.sender, amountToWithdraw, fee);
    }

    /**
     * @dev Fallback function to accept direct ETH deposits.
     */
    receive() external payable {
        deposit();
    }
}
