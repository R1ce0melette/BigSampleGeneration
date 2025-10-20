// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public beneficiary;
    IERC20 public token;
    uint256 public start;
    uint256 public duration;
    uint256 public totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(address _beneficiary, address _token, uint256 _start, uint256 _duration, uint256 _totalAmount) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_token != address(0), "Invalid token");
        require(_duration > 0, "Duration must be > 0");
        require(_totalAmount > 0, "Amount must be > 0");
        beneficiary = _beneficiary;
        token = IERC20(_token);
        start = _start;
        duration = _duration;
        totalAmount = _totalAmount;
    }

    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - released;
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

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "Transfer failed");
        emit TokensReleased(amount);
    }
}
