// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableVault {
    address public owner;
    bool public paused;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused();
    event Resumed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable notPaused {
        require(msg.value > 0, "No ETH sent");
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner notPaused {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Withdraw failed");
        emit Withdrawn(owner, amount);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function resume() external onlyOwner {
        paused = false;
        emit Resumed();
    }
}
