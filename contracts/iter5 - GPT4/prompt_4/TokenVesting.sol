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

    constructor(address _beneficiary, address _token, uint256 _totalAmount, uint256 _duration) {
        beneficiary = _beneficiary;
        token = IERC20(_token);
        totalAmount = _totalAmount;
        duration = _duration;
        start = block.timestamp;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount - released;
        } else {
            uint256 vested = (totalAmount * (block.timestamp - start)) / duration;
            return vested - released;
        }
    }

    function release() external {
        require(msg.sender == beneficiary, "Not beneficiary");
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "Transfer failed");
    }
}
