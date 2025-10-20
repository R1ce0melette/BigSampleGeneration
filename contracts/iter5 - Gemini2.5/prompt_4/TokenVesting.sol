// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Minimal interface for an ERC20 token.
 */
interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @param to The address of the recipient.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @param account The address of the owner.
     * @return The token balance.
     */
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title TokenVesting
 * @dev A token vesting contract that releases tokens gradually over a defined period.
 */
contract TokenVesting {
    // The ERC20 token being vested.
    IERC20 public immutable token;
    // The beneficiary who will receive the vested tokens.
    address public immutable beneficiary;
    // The timestamp when the vesting period begins.
    uint256 public immutable startTimestamp;
    // The duration of the vesting period in seconds.
    uint256 public immutable durationSeconds;
    // The total amount of tokens to be vested.
    uint256 public immutable totalVestingAmount;

    // The amount of tokens that have already been released to the beneficiary.
    uint256 public releasedAmount;

    /**
     * @dev Event emitted when tokens are released.
     * @param beneficiaryAddress The address of the beneficiary.
     * @param amount The amount of tokens released.
     */
    event TokensReleased(address indexed beneficiaryAddress, uint256 amount);

    /**
     * @dev Sets up the token vesting schedule.
     * @param _token The address of the ERC20 token contract.
     * @param _beneficiary The address of the beneficiary.
     * @param _startTimestamp The start time of the vesting period.
     * @param _durationSeconds The duration of the vesting period.
     */
    constructor(
        address _token,
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _durationSeconds
    ) {
        require(_token != address(0), "Token address cannot be zero.");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(_durationSeconds > 0, "Vesting duration must be positive.");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        totalVestingAmount = token.balanceOf(address(this));
        
        require(totalVestingAmount > 0, "Initial vesting amount cannot be zero.");
    }

    /**
     * @dev Calculates the amount of tokens that have vested at a given time.
     * @param _timestamp The time to check for vested amount.
     * @return The amount of tokens that have vested.
     */
    function vestedAmount(uint256 _timestamp) public view returns (uint256) {
        if (_timestamp < startTimestamp) {
            return 0;
        }
        if (_timestamp >= startTimestamp + durationSeconds) {
            return totalVestingAmount;
        }
        
        uint256 timeElapsed = _timestamp - startTimestamp;
        return (totalVestingAmount * timeElapsed) / durationSeconds;
    }

    /**
     * @dev Calculates the amount of tokens that can be released at the current time.
     * @return The amount of releasable tokens.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount(block.timestamp) - releasedAmount;
    }

    /**
     * @dev Releases the vested tokens to the beneficiary.
     * Can be called by anyone, but tokens are sent to the beneficiary.
     */
    function release() public {
        uint256 amountToRelease = releasableAmount();
        require(amountToRelease > 0, "No tokens available for release.");

        releasedAmount += amountToRelease;
        
        emit TokensReleased(beneficiary, amountToRelease);
        
        require(token.transfer(beneficiary, amountToRelease), "Token transfer failed.");
    }
}
