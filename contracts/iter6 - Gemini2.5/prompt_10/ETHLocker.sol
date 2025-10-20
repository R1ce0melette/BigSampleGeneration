// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ETHLocker
 * @dev A contract that allows users to lock ETH for a specified period and earn fixed interest.
 */
contract ETHLocker {
    // Struct to store details of a user's lock
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    // Mapping from user address to their lock details
    mapping(address => Lock) public locks;

    // The annual interest rate (e.g., 5 for 5%)
    uint256 public interestRate;

    // The minimum lock duration in seconds
    uint256 public minLockDuration;

    // The owner of the contract, who can set the interest rate and withdraw contract balance
    address public owner;

    /**
     * @dev Emitted when a user locks ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH locked.
     * @param unlockTime The timestamp when the ETH can be unlocked.
     */
    event Locked(address indexed user, uint256 amount, uint256 unlockTime);

    /**
     * @dev Emitted when a user withdraws their locked ETH and interest.
     * @param user The address of the user.
     * @param amount The principal amount withdrawn.
     * @param interest The interest amount withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount, uint256 interest);

    modifier onlyOwner() {
        require(msg.sender == owner, "ETHLocker: Caller is not the owner.");
        _;
    }

    /**
     * @dev Sets up the contract with an initial interest rate and minimum lock duration.
     * @param _interestRate The annual interest rate in percentage (e.g., 5 for 5%).
     * @param _minLockDurationInDays The minimum lock duration in days.
     */
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
        require(msg.value > 0, "ETHLocker: Lock amount must be greater than 0.");
        require(locks[msg.sender].amount == 0, "ETHLocker: You already have an active lock.");
        require(lockDuration >= minLockDuration, "ETHLocker: Lock duration is below the minimum.");

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
        require(userLock.amount > 0, "ETHLocker: No active lock found.");
        require(block.timestamp >= userLock.unlockTime, "ETHLocker: Lock period has not ended.");

        uint256 principal = userLock.amount;
        uint256 lockDuration = userLock.unlockTime - (block.timestamp - (userLock.unlockTime - userLock.amount)); // A bit of a trick to get original start time
        uint256 interest = (principal * interestRate * lockDuration) / (100 * 365 days);

        // Reset the user's lock
        delete locks[msg.sender];

        // Transfer principal + interest to the user
        (bool success, ) = msg.sender.call{value: principal + interest}("");
        require(success, "ETHLocker: Withdrawal failed.");

        emit Withdrawn(msg.sender, principal, interest);
    }

    /**
     * @dev Allows the owner to change the interest rate.
     * @param _newInterestRate The new annual interest rate.
     */
    function setInterestRate(uint256 _newInterestRate) public onlyOwner {
        interestRate = _newInterestRate;
    }
    
    /**
     * @dev Allows the owner to withdraw the contract balance to fund interest payments.
     */
    function ownerWithdraw() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETHLocker: Owner withdrawal failed.");
    }
}
