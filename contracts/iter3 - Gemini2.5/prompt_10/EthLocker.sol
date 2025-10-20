// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EthLocker
 * @dev A contract that allows users to lock their ETH for a fixed period
 * and earn a fixed interest upon withdrawal.
 */
contract EthLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    // Mapping from user address to their lock details
    mapping(address => Lock) public userLocks;

    // The duration for which the ETH will be locked
    uint256 public immutable lockDuration;
    // The fixed interest rate in percentage (e.g., 5 for 5%)
    uint256 public immutable interestRate;

    address public owner;

    /**
     * @dev Emitted when a user locks their ETH.
     * @param user The address of the user.
     * @param amount The amount of ETH locked.
     * @param unlockTime The timestamp when the ETH can be withdrawn.
     */
    event Locked(address indexed user, uint256 amount, uint256 unlockTime);

    /**
     * @dev Emitted when a user withdraws their locked ETH and interest.
     * @param user The address of the user.
     * @param amount The principal amount withdrawn.
     * @param interest The interest amount earned and withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount, uint256 interest);

    /**
     * @dev Modifier to restrict certain functions to the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets up the contract with a lock duration and interest rate.
     * @param _lockDuration The duration of the lock in seconds.
     * @param _interestRate The fixed interest rate (e.g., 5 for 5%).
     */
    constructor(uint256 _lockDuration, uint256 _interestRate) {
        require(_lockDuration > 0, "Lock duration must be greater than zero.");
        require(_interestRate > 0, "Interest rate must be greater than zero.");
        
        owner = msg.sender;
        lockDuration = _lockDuration;
        interestRate = _interestRate;
    }

    /**
     * @dev Allows a user to lock their ETH.
     * A user can only have one active lock at a time.
     */
    function lock() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        require(userLocks[msg.sender].amount == 0, "You already have an active lock.");

        uint256 unlockTime = block.timestamp + lockDuration;
        userLocks[msg.sender] = Lock(msg.value, unlockTime);

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    /**
     * @dev Allows a user to withdraw their locked ETH plus earned interest
     * after the lock duration has passed.
     */
    function withdraw() public {
        Lock storage userLock = userLocks[msg.sender];
        require(userLock.amount > 0, "You have no active lock.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not expired yet.");

        uint256 principal = userLock.amount;
        uint256 interest = (principal * interestRate) / 100;
        uint256 totalPayout = principal + interest;

        require(address(this).balance >= totalPayout, "Contract has insufficient funds to pay interest.");

        // Reset the user's lock before sending funds to prevent re-entrancy
        userLock.amount = 0;
        userLock.unlockTime = 0;

        payable(msg.sender).transfer(totalPayout);

        emit Withdrawn(msg.sender, principal, interest);
    }

    /**
     * @dev Allows the owner to fund the contract to ensure it can pay interest.
     */
    function fund() public payable onlyOwner {
        // The owner can send ETH to this function to fund the contract.
    }

    /**
     * @dev Returns the current balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
