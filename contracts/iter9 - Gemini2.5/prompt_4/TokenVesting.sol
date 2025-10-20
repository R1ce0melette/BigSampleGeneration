// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenVesting {
    address public immutable token;
    address public immutable beneficiary;
    uint256 public immutable vestingStart;
    uint256 public immutable vestingDuration;
    uint256 public immutable totalVestingAmount;
    uint256 public releasedAmount;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        address _token,
        address _beneficiary,
        uint256 _vestingDuration,
        uint256 _totalVestingAmount
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address.");
        require(_token != address(0), "Token cannot be the zero address.");
        require(_vestingDuration > 0, "Vesting duration must be greater than zero.");
        require(_totalVestingAmount > 0, "Total vesting amount must be greater than zero.");

        token = _token;
        beneficiary = _beneficiary;
        vestingStart = block.timestamp;
        vestingDuration = _vestingDuration;
        totalVestingAmount = _totalVestingAmount;
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < vestingStart) {
            return 0;
        }
        if (block.timestamp >= vestingStart + vestingDuration) {
            return totalVestingAmount;
        }
        
        uint256 timeElapsed = block.timestamp - vestingStart;
        return (totalVestingAmount * timeElapsed) / vestingDuration;
    }

    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - releasedAmount;
    }

    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "No tokens available for release.");
        
        releasedAmount += unreleased;
        IERC20(token).transfer(beneficiary, unreleased);
        emit TokensReleased(beneficiary, unreleased);
    }
}
