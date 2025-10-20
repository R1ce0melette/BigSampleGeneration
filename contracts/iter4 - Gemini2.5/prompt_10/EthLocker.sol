// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthLocker {
    address public owner;
    uint256 public interestRateBps; // Interest rate in basis points (e.g., 500 for 5%)
    uint256 public lockDuration;

    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 principal, uint256 interest);
    event FundsDeposited(address indexed from, uint256 amount);

    constructor(uint256 _interestRateBps, uint256 _lockDurationSeconds) {
        owner = msg.sender;
        interestRateBps = _interestRateBps;
        lockDuration = _lockDurationSeconds;
    }

    function depositInterestFund() public payable {
        require(msg.sender == owner, "Only owner can deposit funds.");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function lock() public payable {
        require(msg.value > 0, "Cannot lock zero ETH.");
        require(locks[msg.sender].amount == 0, "You already have an active lock.");

        uint256 unlockTime = block.timestamp + lockDuration;
        locks[msg.sender] = Lock(msg.value, unlockTime);

        emit Locked(msg.sender, msg.value, unlockTime);
    }

    function unlock() public {
        Lock storage userLock = locks[msg.sender];
        require(userLock.amount > 0, "You have no ETH locked.");
        require(block.timestamp >= userLock.unlockTime, "Lock period has not ended.");

        uint256 principal = userLock.amount;
        uint256 interest = (principal * interestRateBps) / 10000;
        uint256 totalPayout = principal + interest;

        require(address(this).balance >= totalPayout, "Insufficient contract balance for payout.");

        delete locks[msg.sender];

        emit Unlocked(msg.sender, principal, interest);
        payable(msg.sender).transfer(totalPayout);
    }

    function getLockDetails(address _user) public view returns (uint256 amount, uint256 unlockTime) {
        Lock storage userLock = locks[_user];
        return (userLock.amount, userLock.unlockTime);
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
