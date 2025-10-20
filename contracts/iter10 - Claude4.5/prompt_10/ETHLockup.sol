// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETHLockup {
    struct Lockup {
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 interestRate;
        bool withdrawn;
    }

    mapping(address => Lockup[]) public userLockups;
    uint256 public defaultInterestRate; // in basis points (e.g., 500 = 5%)
    uint256 public defaultLockPeriod; // in seconds

    event ETHLocked(address indexed user, uint256 amount, uint256 unlockTime, uint256 interestRate);
    event ETHUnlocked(address indexed user, uint256 principal, uint256 interest);
    event InterestRateUpdated(uint256 newRate);
    event LockPeriodUpdated(uint256 newPeriod);

    constructor(uint256 _interestRate, uint256 _lockPeriodInDays) {
        defaultInterestRate = _interestRate;
        defaultLockPeriod = _lockPeriodInDays * 1 days;
    }

    function lockETH() external payable {
        require(msg.value > 0, "Must lock some ETH");

        uint256 unlockTime = block.timestamp + defaultLockPeriod;

        userLockups[msg.sender].push(Lockup({
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            interestRate: defaultInterestRate,
            withdrawn: false
        }));

        emit ETHLocked(msg.sender, msg.value, unlockTime, defaultInterestRate);
    }

    function lockETHWithCustomPeriod(uint256 durationInDays) external payable {
        require(msg.value > 0, "Must lock some ETH");
        require(durationInDays > 0, "Duration must be greater than 0");

        uint256 unlockTime = block.timestamp + (durationInDays * 1 days);

        userLockups[msg.sender].push(Lockup({
            amount: msg.value,
            lockTime: block.timestamp,
            unlockTime: unlockTime,
            interestRate: defaultInterestRate,
            withdrawn: false
        }));

        emit ETHLocked(msg.sender, msg.value, unlockTime, defaultInterestRate);
    }

    function unlockETH(uint256 lockupIndex) external {
        require(lockupIndex < userLockups[msg.sender].length, "Invalid lockup index");
        Lockup storage lockup = userLockups[msg.sender][lockupIndex];
        
        require(!lockup.withdrawn, "Already withdrawn");
        require(block.timestamp >= lockup.unlockTime, "Lockup period not yet ended");

        uint256 principal = lockup.amount;
        uint256 interest = (principal * lockup.interestRate) / 10000;
        uint256 totalAmount = principal + interest;

        lockup.withdrawn = true;

        require(address(this).balance >= totalAmount, "Insufficient contract balance");

        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");

        emit ETHUnlocked(msg.sender, principal, interest);
    }

    function getUserLockupCount(address user) external view returns (uint256) {
        return userLockups[user].length;
    }

    function getUserLockup(address user, uint256 index) external view returns (
        uint256 amount,
        uint256 lockTime,
        uint256 unlockTime,
        uint256 interestRate,
        bool withdrawn
    ) {
        require(index < userLockups[user].length, "Invalid lockup index");
        Lockup memory lockup = userLockups[user][index];
        return (lockup.amount, lockup.lockTime, lockup.unlockTime, lockup.interestRate, lockup.withdrawn);
    }

    function calculateInterest(address user, uint256 lockupIndex) external view returns (uint256) {
        require(lockupIndex < userLockups[user].length, "Invalid lockup index");
        Lockup memory lockup = userLockups[user][lockupIndex];
        return (lockup.amount * lockup.interestRate) / 10000;
    }

    function fundContract() external payable {
        require(msg.value > 0, "Must send some ETH");
    }

    receive() external payable {}
}
