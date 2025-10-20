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
 * The tokens are released gradually over a defined period, with an initial cliff.
 */
contract TokenVesting {
    // The beneficiary who will receive the vested tokens.
    address public immutable beneficiary;

    // The start timestamp of the vesting period.
    uint256 public immutable start;

    // The duration of the cliff in seconds. Before the cliff, no tokens can be released.
    uint256 public immutable cliffDuration;

    // The total duration of the vesting period in seconds.
    uint256 public immutable vestingDuration;

    // The total amount of tokens that are subject to vesting.
    uint256 public immutable totalVestableAmount;

    // The ERC20 token being vested.
    IERC20 public immutable token;

    // The amount of tokens that have already been released to the beneficiary.
    uint256 public releasedAmount;

    /**
     * @dev Emitted when tokens are released.
     * @param beneficiary The recipient of the tokens.
     * @param amount The amount of tokens released.
     */
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /**
     * @dev Creates a new TokenVesting contract.
     * @param _beneficiary The address of the beneficiary.
     * @param _start The start time of the vesting period (Unix timestamp).
     * @param _cliffDuration The duration of the cliff period in seconds.
     * @param _vestingDuration The total duration of the vesting period in seconds.
     * @param _tokenAddress The address of the ERC20 token contract.
     */
    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        address _tokenAddress
    ) {
        require(_beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        require(_vestingDuration > 0, "TokenVesting: duration must be greater than 0");
        require(_cliffDuration <= _vestingDuration, "TokenVesting: cliff must be less than or equal to duration");
        require(_tokenAddress != address(0), "TokenVesting: token is the zero address");

        beneficiary = _beneficiary;
        start = _start;
        cliffDuration = _cliffDuration;
        vestingDuration = _vestingDuration;
        token = IERC20(_tokenAddress);
        totalVestableAmount = token.balanceOf(address(this));
        require(totalVestableAmount > 0, "TokenVesting: initial balance is 0");
    }

    /**
     * @dev Releases the vested tokens to the beneficiary.
     */
    function release() public {
        uint256 unreleased = _vestedAmount() - releasedAmount;
        require(unreleased > 0, "TokenVesting: no tokens to release");

        releasedAmount += unreleased;
        
        require(token.transfer(beneficiary, unreleased), "TokenVesting: token transfer failed");

        emit TokensReleased(beneficiary, unreleased);
    }

    /**
     * @dev Calculates the amount of tokens that have vested at the current time.
     * @return The amount of vested tokens.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentTime = block.timestamp;
        
        if (currentTime < start + cliffDuration) {
            return 0;
        }
        
        if (currentTime >= start + vestingDuration) {
            return totalVestableAmount;
        }

        return (totalVestableAmount * (currentTime - start)) / vestingDuration;
    }

    /**
     * @dev Public view function to check the amount of vested tokens.
     * @return The amount of vested tokens.
     */
    function vestedAmount() public view returns (uint256) {
        return _vestedAmount();
    }
}
