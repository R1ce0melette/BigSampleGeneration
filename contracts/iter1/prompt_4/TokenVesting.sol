// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public owner;
    IERC20 public token;
    address public beneficiary;
    uint256 public start;
    uint256 public duration;
    uint256 public totalAmount;
    uint256 public released;

    event TokensReleased(address beneficiary, uint256 amount);

    constructor(address _token, address _beneficiary, uint256 _start, uint256 _duration, uint256 _totalAmount) {
        owner = msg.sender;
        token = IERC20(_token);
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        totalAmount = _totalAmount;
        released = 0;
    }

    function release() external {
        require(block.timestamp >= start, "Vesting not started");
        uint256 vested = vestedAmount();
        uint256 unreleased = vested - released;
        require(unreleased > 0, "No tokens to release");
        released += unreleased;
        require(token.transfer(beneficiary, unreleased), "Transfer failed");
        emit TokensReleased(beneficiary, unreleased);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount;
        } else {
            return (totalAmount * (block.timestamp - start)) / duration;
        }
    }
}
