// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockedWallet {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;
    uint256 public constant INTEREST_RATE = 10; // 10% fixed interest

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount, uint256 interest);

    /**
     * @dev Locks a certain amount of ETH for a specified duration.
     * @param _lockDurationInDays The duration in days for which the ETH will be locked.
     */
    function lock(uint256 _lockDurationInDays) public payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        require(locks[msg.sender].amount == 0, "You already have a lock. Unlock first.");
        require(_lockDurationInDays > 0, "Lock duration must be greater than zero.");

        uint256 unlockTime = block.timestamp + (_lockDurationInDays * 1 days);
        locks[msg.sender] = Lock(msg.value, unlockTime);

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Unlocks the ETH and transfers the principal plus interest to the user.
     */
    function unlock() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "No funds locked.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not ended.");

        uint256 principal = userLock.amount;
        uint256 interest = (principal * INTEREST_RATE) / 100;
        uint256 totalAmount = principal + interest;

        // Ensure the contract has enough balance to pay out.
        // This is a simple model; a real-world contract would need a more robust way to manage funds for interest.
        require(address(this).balance >= totalAmount, "Contract has insufficient funds for payout.");

        delete locks[msg.sender]; // Reset the lock

        emit Unlocked(msg.sender, principal, interest);
        payable(msg.sender).transfer(totalAmount);
    }

    /**
     * @dev Gets the details of a user's lock.
     * @return The locked amount and the unlock timestamp.
     */
    function getLockDetails() public view returns (uint256, uint256) {
        Lock storage userLock = locks[msg.sender];
        return (userLock.amount, userLock.unlockTime);
    }
}
