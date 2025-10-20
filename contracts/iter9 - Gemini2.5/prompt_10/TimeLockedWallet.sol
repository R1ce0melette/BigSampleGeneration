// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockedWallet {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;
    uint256 public constant INTEREST_RATE = 10; // 10% interest

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount);

    /**
     * @dev Locks a certain amount of ETH for a specified duration.
     * @param _lockDurationInDays The duration in days for which the ETH will be locked.
     */
    function lock(uint256 _lockDurationInDays) public payable {
        require(msg.value > 0, "Lock amount must be greater than zero.");
        require(locks[msg.sender].amount == 0, "You already have a lock. Please unlock first.");
        require(_lockDurationInDays > 0, "Lock duration must be greater than zero.");

        uint256 unlockTime = block.timestamp + (_lockDurationInDays * 1 days);
        locks[msg.sender] = Lock(msg.value, unlockTime);

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Unlocks the ETH and transfers it to the user with interest.
     */
    function unlock() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "No funds locked.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not ended yet.");

        uint256 interest = (userLock.amount * INTEREST_RATE) / 100;
        uint256 totalAmount = userLock.amount + interest;

        // Reset the lock before transferring to prevent re-entrancy attacks
        delete locks[msg.sender];

        payable(msg.sender).transfer(totalAmount);

        emit Unlocked(msg.sender, totalAmount);
    }

    /**
     * @dev Retrieves the lock details for a specific user.
     * @param _user The address of the user.
     * @return The locked amount and the unlock time.
     */
    function getLockDetails(address _user) public view returns (uint256, uint256) {
        return (locks[_user].amount, locks[_user].unlockTime);
    }
}
