// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PausableTransfer {
    address public owner;
    bool public paused;

    event Paused();
    event Resumed();
    event Transferred(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function resume() external onlyOwner {
        paused = false;
        emit Resumed();
    }

    function transfer(address payable to, uint256 amount) external onlyOwner whenNotPaused {
        require(to != address(0), "Invalid address");
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit Transferred(to, amount);
    }

    function fund() external payable {}
}
