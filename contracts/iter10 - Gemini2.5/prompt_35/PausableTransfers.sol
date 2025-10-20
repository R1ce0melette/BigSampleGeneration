// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableTransfers {
    address public owner;
    bool public paused;
    mapping(address => uint256) public balances;

    event Paused(address account);
    event Unpaused(address account);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function pause() public onlyOwner {
        require(!paused, "Contract is already paused.");
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        require(paused, "Contract is not paused.");
        paused = false;
        emit Unpaused(msg.sender);
    }

    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
