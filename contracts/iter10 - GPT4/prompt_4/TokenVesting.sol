// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenVesting {
    address public beneficiary;
    IERC20 public token;
    uint256 public start;
    uint256 public duration;
    uint256 public totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(address _beneficiary, address _token, uint256 _totalAmount, uint256 _duration) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_token != address(0), "Invalid token");
        require(_totalAmount > 0, "Amount must be positive");
        require(_duration > 0, "Duration must be positive");
        beneficiary = _beneficiary;
        token = IERC20(_token);
        totalAmount = _totalAmount;
        duration = _duration;
        start = block.timestamp;
    }

    function releasable() public view returns (uint256) {
        if (block.timestamp < start) return 0;
        uint256 elapsed = block.timestamp - start;
        if (elapsed >= duration) return totalAmount - released;
        return (totalAmount * elapsed) / duration - released;
    }

    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "No tokens to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "Transfer failed");
        emit TokensReleased(amount);
    }
}
