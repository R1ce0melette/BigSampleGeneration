// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public beneficiary;
    uint256 public start;
    uint256 public duration;
    uint256 public totalTokens;
    uint256 public releasedTokens;
    IERC20 public token;

    event TokensReleased(address beneficiary, uint256 amount);

    constructor(address _beneficiary, uint256 _duration, uint256 _totalTokens, address _tokenAddress) {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(_tokenAddress != address(0), "Token cannot be the zero address");
        require(_duration > 0, "Duration must be greater than zero");
        require(_totalTokens > 0, "Total tokens must be greater than zero");

        beneficiary = _beneficiary;
        start = block.timestamp;
        duration = _duration;
        totalTokens = _totalTokens;
        token = IERC20(_tokenAddress);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        }
        if (block.timestamp >= start + duration) {
            return totalTokens;
        }
        return (totalTokens * (block.timestamp - start)) / duration;
    }

    function release() public {
        uint256 vested = vestedAmount();
        uint256 releasable = vested - releasedTokens;
        
        require(releasable > 0, "No tokens available for release");

        releasedTokens += releasable;
        emit TokensReleased(beneficiary, releasable);
        token.transfer(beneficiary, releasable);
    }

    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - releasedTokens;
    }
}
