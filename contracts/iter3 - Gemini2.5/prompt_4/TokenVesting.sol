// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20
 * @dev Interface for the ERC20 standard.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One way to mitigate this risk is to first reduce the
     * spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract TokenVesting {
    // The ERC20 token being vested
    IERC20 public immutable token;
    // The beneficiary of the vested tokens
    address public immutable beneficiary;
    // The start timestamp of the vesting period
    uint64 public immutable vestingStart;
    // The duration of the vesting period in seconds
    uint64 public immutable vestingDuration;
    // The total amount of tokens to be vested
    uint256 public immutable totalVestingAmount;

    // The amount of tokens that have already been released
    uint256 public releasedAmount;

    /**
     * @dev Emitted when tokens are released to the beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of tokens released.
     */
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /**
     * @dev Creates a new TokenVesting contract.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _beneficiary The address of the beneficiary.
     * @param _vestingStart The start timestamp of the vesting period.
     * @param _vestingDuration The duration of the vesting period in seconds.
     * @param _totalVestingAmount The total amount of tokens to be vested.
     */
    constructor(
        address _tokenAddress,
        address _beneficiary,
        uint64 _vestingStart,
        uint64 _vestingDuration,
        uint256 _totalVestingAmount
    ) {
        require(_tokenAddress != address(0), "Token address cannot be zero.");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero.");
        require(_vestingDuration > 0, "Vesting duration must be greater than zero.");
        require(_totalVestingAmount > 0, "Total vesting amount must be greater than zero.");

        token = IERC20(_tokenAddress);
        beneficiary = _beneficiary;
        vestingStart = _vestingStart;
        vestingDuration = _vestingDuration;
        totalVestingAmount = _totalVestingAmount;
    }

    /**
     * @dev Releases the vested tokens to the beneficiary.
     */
    function release() public {
        require(msg.sender == beneficiary, "Only the beneficiary can release tokens.");
        
        uint256 releasable = releasableAmount();
        require(releasable > 0, "No tokens available for release.");

        releasedAmount += releasable;
        
        bool sent = token.transfer(beneficiary, releasable);
        require(sent, "Token transfer failed.");

        emit TokensReleased(beneficiary, releasable);
    }

    /**
     * @dev Calculates the amount of tokens that have vested at the current time.
     * @return The amount of vested tokens.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 currentTime = block.timestamp;

        if (currentTime < vestingStart) {
            return 0;
        }
        
        if (currentTime >= vestingStart + vestingDuration) {
            return totalVestingAmount;
        }

        uint256 timeElapsed = currentTime - vestingStart;
        return (totalVestingAmount * timeElapsed) / vestingDuration;
    }

    /**
     * @dev Calculates the amount of tokens that can be released at the current time.
     * @return The amount of releasable tokens.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - releasedAmount;
    }

    /**
     * @dev Returns the total balance of the token held by this contract.
     */
    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
