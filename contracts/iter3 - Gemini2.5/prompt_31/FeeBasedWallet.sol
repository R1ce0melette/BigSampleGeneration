// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeeBasedWallet
 * @dev A wallet contract that allows users to deposit and withdraw ETH,
 * with a 1% fee on withdrawals that is collected by the contract owner.
 */
contract FeeBasedWallet {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public constant WITHDRAWAL_FEE_PERCENT = 1;

    /**
     * @dev Emitted when a user deposits ETH into their balance.
     * @param user The address of the depositor.
     * @param amount The amount deposited.
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws ETH from their balance.
     * @param user The address of the withdrawer.
     * @param amount The amount withdrawn before the fee.
     * @param fee The fee collected by the owner.
     */
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);

    /**
     * @dev Emitted when the owner withdraws the collected fees.
     * @param amount The total amount of fees withdrawn.
     */
    event FeesCollected(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows a user to deposit ETH into their wallet balance.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw a specified amount from their balance.
     * A 1% fee is deducted from the withdrawal amount and sent to the contract owner.
     * @param _amount The amount the user wishes to withdraw.
     */
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");

        uint256 fee = (_amount * WITHDRAWAL_FEE_PERCENT) / 100;
        uint256 amountToUser = _amount - fee;

        require(address(this).balance >= _amount, "Contract has insufficient funds for this withdrawal.");

        balances[msg.sender] -= _amount;

        // Transfer the user's portion
        payable(msg.sender).transfer(amountToUser);
        // Transfer the fee to the owner
        payable(owner).transfer(fee);

        emit Withdrawn(msg.sender, _amount, fee);
    }

    /**
     * @dev This function is deprecated in favor of direct fee transfer, but can be used
     * if fees are held in the contract.
     */
    function collectFees() public onlyOwner {
        // In this implementation, fees are sent directly to the owner on withdrawal.
        // If fees were to be accumulated in the contract, this function would be used.
        // For example, if the fee transfer was to `address(this)`, then:
        // uint256 feeBalance = address(this).balance - totalUserBalances;
        // payable(owner).transfer(feeBalance);
        // emit FeesCollected(feeBalance);
        revert("Fees are transferred directly on withdrawal.");
    }

    /**
     * @dev Returns the balance of a specific user.
     */
    function getUserBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }

    /**
     * @dev Returns the total balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
