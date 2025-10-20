// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public beneficiary;
    uint256 public start;
    uint256 public duration;
    uint256 public totalVestingAmount;
    uint256 public releasedAmount;
    IERC20 public token;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(address _beneficiary, uint256 _start, uint256 _duration, uint256 _totalVestingAmount, address _tokenAddress) {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address.");
        require(_duration > 0, "Duration must be greater than zero.");
        require(_totalVestingAmount > 0, "Total vesting amount must be greater than zero.");
        require(_tokenAddress != address(0), "Token address cannot be the zero address.");

        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        totalVestingAmount = _totalVestingAmount;
        token = IERC20(_tokenAddress);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        }
        if (block.timestamp >= start + duration) {
            return totalVestingAmount;
        }
        
        uint256 timeElapsed = block.timestamp - start;
        return (totalVestingAmount * timeElapsed) / duration;
    }

    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - releasedAmount;
    }

    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "No tokens available for release.");
        
        releasedAmount += unreleased;
        require(token.transfer(beneficiary, unreleased), "Token transfer failed.");
        
        emit TokensReleased(beneficiary, unreleased);
    }
}
