// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public immutable token;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable totalVestingAmount;

    uint256 public releasedAmount;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        address _tokenAddress,
        address _beneficiary,
        uint256 _start,
        uint256 _duration,
        uint256 _totalVestingAmount
    ) {
        require(_tokenAddress != address(0), "Token address cannot be zero.");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(_duration > 0, "Duration must be greater than zero.");
        require(_totalVestingAmount > 0, "Total vesting amount must be greater than zero.");

        token = _tokenAddress;
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        totalVestingAmount = _totalVestingAmount;
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

    function release() public {
        require(msg.sender == beneficiary, "Only the beneficiary can release tokens.");
        uint256 releasableAmount = vestedAmount() - releasedAmount;
        require(releasableAmount > 0, "No tokens available for release.");

        releasedAmount += releasableAmount;
        emit TokensReleased(beneficiary, releasableAmount);
        IERC20(token).transfer(beneficiary, releasableAmount);
    }

    function totalTokensHeld() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
