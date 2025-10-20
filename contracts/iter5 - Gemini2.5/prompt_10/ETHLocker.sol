// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETHLocker
 * @dev A contract that allows users to lock ETH for a fixed period and earn interest.
 */
contract ETHLocker {
    // The annual interest rate in percentage (e.g., 5 for 5%).
    uint256 public interestRate;
    // The minimum duration for which ETH can be locked, in seconds.
    uint256 public minLockDuration;

    // Structure to represent a user's lock.
    struct Lock {
        uint256 amount;
        uint256 unlockTimestamp;
        bool active;
    }

    // Mapping from a user's address to their lock details.
    mapping(address => Lock) public userLocks;

    /**
     * @dev Event emitted when a user locks ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH locked.
     * @param unlockTimestamp The timestamp when the ETH can be unlocked.
     */
    event ETHLocked(address indexed user, uint256 amount, uint256 unlockTimestamp);

    /**
     * @dev Event emitted when a user unlocks their ETH and claims interest.
     * @param user The address of the user.
     * @param principal The original amount of ETH unlocked.
     * @param interest The interest earned.
     */
    event ETHUnlocked(address indexed user, uint256 principal, uint256 interest);

    /**
     * @dev Sets the interest rate and minimum lock duration upon deployment.
     * @param _interestRate The annual interest rate (e.g., 5 for 5%).
     * @param _minLockDuration The minimum lock duration in seconds.
     */
    constructor(uint256 _interestRate, uint256 _minLockDuration) {
        require(_interestRate > 0 && _interestRate <= 100, "Interest rate must be between 1 and 100.");
        require(_minLockDuration > 0, "Minimum lock duration must be positive.");
        interestRate = _interestRate;
        minLockDuration = _minLockDuration;
    }

    /**
     * @dev Locks a user's ETH for a specified duration.
     * - The user must not have an active lock.
     * - The lock duration must meet the minimum requirement.
     * @param _lockDuration The duration to lock the ETH for, in seconds.
     */
    function lockETH(uint256 _lockDuration) public payable {
        require(!userLocks[msg.sender].active, "You already have an active lock.");
        require(msg.value > 0, "Lock amount must be greater than zero.");
        require(_lockDuration >= minLockDuration, "Lock duration is less than the minimum required.");

        uint256 unlockTimestamp = block.timestamp + _lockDuration;
        userLocks[msg.sender] = Lock({
            amount: msg.value,
            unlockTimestamp: unlockTimestamp,
            active: true
        });

        emit ETHLocked(msg.sender, msg.value, unlockTimestamp);
    }

    /**
     * @dev Unlocks the user's ETH and transfers the principal plus interest.
     * - The user must have an active lock.
     * - The lock period must have passed.
     */
    function unlockETH() public {
        Lock storage userLock = userLocks[msg.sender];
        require(userLock.active, "You do not have an active lock.");
        require(block.timestamp >= userLock.unlockTimestamp, "Lock period has not yet ended.");

        uint256 principal = userLock.amount;
        uint256 lockDuration = userLock.unlockTimestamp - (block.timestamp - (userLock.unlockTimestamp - userLocks[msg.sender].unlockTimestamp)); // Simplified way to get original duration
        uint256 interest = calculateInterest(principal, lockDuration);
        uint256 totalPayout = principal + interest;

        userLock.active = false; // Deactivate the lock

        emit ETHUnlocked(msg.sender, principal, interest);

        payable(msg.sender).transfer(totalPayout);
    }

    /**
     * @dev Calculates the interest earned on a locked amount over a duration.
     * @param _principal The principal amount.
     * @param _duration The duration of the lock in seconds.
     * @return The calculated interest amount.
     */
    function calculateInterest(uint256 _principal, uint256 _duration) public view returns (uint256) {
        // Interest is calculated as: (principal * rate * duration) / (100 * 365 days)
        return (_principal * interestRate * _duration) / (100 * 365 days);
    }

    /**
     * @dev Retrieves the details of a user's lock.
     * @param _user The address of the user.
     * @return A tuple containing the locked amount, unlock timestamp, and active status.
     */
    function getLockDetails(address _user) public view returns (uint256, uint256, bool) {
        Lock storage userLock = userLocks[_user];
        return (userLock.amount, userLock.unlockTimestamp, userLock.active);
    }
}
