// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVesting {
    address public beneficiary;
    address public owner;
    uint256 public totalTokens;
    uint256 public tokensReleased;
    uint256 public startTime;
    uint256 public vestingDuration;
    uint256 public cliffDuration;

    event TokensReleased(uint256 amount);
    event VestingRevoked();

    constructor(
        address _beneficiary,
        uint256 _totalTokens,
        uint256 _cliffDurationInDays,
        uint256 _vestingDurationInDays
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_totalTokens > 0, "Total tokens must be greater than 0");
        require(_vestingDurationInDays > 0, "Vesting duration must be greater than 0");
        require(_cliffDurationInDays <= _vestingDurationInDays, "Cliff cannot exceed vesting duration");

        owner = msg.sender;
        beneficiary = _beneficiary;
        totalTokens = _totalTokens;
        tokensReleased = 0;
        startTime = block.timestamp;
        cliffDuration = _cliffDurationInDays * 1 days;
        vestingDuration = _vestingDurationInDays * 1 days;
    }

    function release(uint256 amount) external {
        require(msg.sender == beneficiary, "Only beneficiary can release tokens");
        require(block.timestamp >= startTime + cliffDuration, "Cliff period has not ended");

        uint256 vestedAmount = calculateVestedAmount();
        uint256 releasableAmount = vestedAmount - tokensReleased;

        require(releasableAmount >= amount, "Insufficient vested tokens");
        require(amount > 0, "Amount must be greater than 0");

        tokensReleased += amount;

        // In a real implementation, this would transfer actual tokens
        // For this simple contract, we just track the release
        emit TokensReleased(amount);
    }

    function calculateVestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        } else if (block.timestamp >= startTime + vestingDuration) {
            return totalTokens;
        } else {
            uint256 timeVested = block.timestamp - startTime;
            return (totalTokens * timeVested) / vestingDuration;
        }
    }

    function getReleasableAmount() external view returns (uint256) {
        uint256 vestedAmount = calculateVestedAmount();
        return vestedAmount - tokensReleased;
    }

    function getVestingInfo() external view returns (
        address _beneficiary,
        uint256 _totalTokens,
        uint256 _tokensReleased,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) {
        return (
            beneficiary,
            totalTokens,
            tokensReleased,
            startTime,
            cliffDuration,
            vestingDuration
        );
    }

    function getTimeRemaining() external view returns (uint256) {
        uint256 endTime = startTime + vestingDuration;
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }
}
