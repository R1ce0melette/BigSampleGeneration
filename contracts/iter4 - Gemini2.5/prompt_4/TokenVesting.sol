// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public beneficiary;
    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public totalVestingAmount;
    uint256 public released;
    IERC20 public token;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        address _tokenAddress,
        address _beneficiary,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _totalVestingAmount
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address.");
        require(_tokenAddress != address(0), "Token cannot be the zero address.");
        
        token = IERC20(_tokenAddress);
        beneficiary = _beneficiary;
        start = _start;
        cliff = _start + _cliffDuration;
        duration = _duration;
        totalVestingAmount = _totalVestingAmount;
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        }
        if (block.timestamp >= start + duration) {
            return totalVestingAmount;
        }
        
        uint256 timeElapsed = block.timestamp - start;
        return (totalVestingAmount * timeElapsed) / duration;
    }

    function release() public {
        uint256 releasable = vestedAmount() - released;
        require(releasable > 0, "No tokens available for release.");
        
        released += releasable;
        emit TokensReleased(beneficiary, releasable);
        require(token.transfer(beneficiary, releasable), "Token transfer failed.");
    }
}
