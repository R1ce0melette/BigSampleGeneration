// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PausableWallet
 * @dev A wallet contract that allows the owner to pause and resume ETH transfers.
 */
contract PausableWallet {

    address public owner;
    bool public isPaused;
    mapping(address => uint256) public balances;

    event Paused();
    event Unpaused();
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier whenNotPaused() {
        require(!isPaused, "Contract is currently paused.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Pauses the contract, preventing deposits and withdrawals.
     */
    function pause() public onlyOwner {
        require(!isPaused, "Contract is already paused.");
        isPaused = true;
        emit Paused();
    }

    /**
     * @dev Resumes the contract, allowing deposits and withdrawals.
     */
    function unpause() public onlyOwner {
        require(isPaused, "Contract is not paused.");
        isPaused = false;
        emit Unpaused();
    }

    /**
     * @dev Deposits ETH into the user's balance.
     */
    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be positive.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Withdraws ETH from the user's balance.
     */
    function withdraw(uint256 _amount) public whenNotPaused {
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }
}
