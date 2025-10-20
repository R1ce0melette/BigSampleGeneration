// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Minimal interface for the ERC20 standard.
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title TokenVesting
 * @dev A contract that handles the vesting of ERC20 tokens for a beneficiary.
 * The tokens are released gradually over a defined period.
 */
contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable startTimestamp;
    uint256 public immutable vestingDuration;
    uint256 public immutable totalVestableAmount;
    IERC20 public immutable token;
    uint256 public releasedAmount;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    /**
     * @dev Creates a new TokenVesting contract.
     * @param _beneficiary The address of the beneficiary.
     * @param _startTimestamp The start time of the vesting period (Unix timestamp).
     * @param _vestingDuration The total duration of the vesting period in seconds.
     * @param _tokenAddress The address of the ERC20 token contract.
     */
    constructor(
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _vestingDuration,
        address _tokenAddress
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(_vestingDuration > 0, "Vesting duration must be greater than 0");
        require(_tokenAddress != address(0), "Token address cannot be the zero address");

        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        vestingDuration = _vestingDuration;
        token = IERC20(_tokenAddress);
        totalVestableAmount = token.balanceOf(address(this));
        require(totalVestableAmount > 0, "Initial token balance must be greater than 0");
    }

    /**
     * @dev Releases the vested tokens to the beneficiary.
     */
    function release() public {
        uint256 vested = vestedAmount();
        uint256 releasable = vested - releasedAmount;
        require(releasable > 0, "No tokens available to release");

        releasedAmount += releasable;
        
        require(token.transfer(beneficiary, releasable), "Token transfer failed");

        emit TokensReleased(beneficiary, releasable);
    }

    /**
     * @dev Calculates the amount of tokens that have vested at the current time.
     * @return The amount of vested tokens.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime < startTimestamp) {
            return 0;
        }
        
        uint256 elapsedTime = currentTime - startTimestamp;
        if (elapsedTime >= vestingDuration) {
            return totalVestableAmount;
        }

        return (totalVestableAmount * elapsedTime) / vestingDuration;
    }
}
