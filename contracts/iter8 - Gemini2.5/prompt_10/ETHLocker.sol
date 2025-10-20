// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETHLocker
 * @dev A contract that allows users to lock ETH for a specified period and earn fixed interest.
 */
contract ETHLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;
    uint256 public interestRate; // Annual interest rate, e.g., 5 for 5%
    uint256 public minLockDuration;
    address public owner;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount, uint256 interest);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor(uint256 _interestRate, uint256 _minLockDurationInDays) {
        owner = msg.sender;
        interestRate = _interestRate;
        minLockDuration = _minLockDurationInDays * 1 days;
    }

    /**
     * @dev Locks a specified amount of ETH for a given duration.
     * @param _lockDurationInDays The duration to lock the ETH in days.
     */
    function lock(uint256 _lockDurationInDays) public payable {
        uint256 lockDuration = _lockDurationInDays * 1 days;
        require(msg.value > 0, "Lock amount must be greater than 0.");
        require(locks[msg.sender].amount == 0, "You already have an active lock.");
        require(lockDuration >= minLockDuration, "Lock duration is below the minimum.");

        uint256 unlockTime = block.timestamp + lockDuration;
        locks[msg.sender] = Lock({
            amount: msg.value,
            unlockTime: unlockTime
        });

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Withdraws the locked ETH and accrued interest after the lock period has passed.
     */
    function withdraw() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "No active lock found.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not ended.");

        uint256 principal = userLock.amount;
        uint256 lockDuration = userLock.unlockTime - (block.timestamp - (userLock.unlockTime - userLock.amount)); // Simplified way to get original start time
        uint256 interest = (principal * interestRate * lockDuration) / (100 * 365 days);

        delete locks[msg.sender];

        (bool success, ) = msg.sender.call{value: principal + interest}("");
        require(success, "Withdrawal failed.");

        emit Withdrawn(msg.sender, principal, interest);
    }

    function setInterestRate(uint256 _newInterestRate) public onlyOwner {
        interestRate = _newInterestRate;
    }
    
    function ownerWithdraw() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Owner withdrawal failed.");
    }
}
