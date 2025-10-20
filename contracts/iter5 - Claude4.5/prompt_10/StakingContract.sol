// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingContract {
    uint256 public constant INTEREST_RATE = 10; // 10% annual interest
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    struct Stake {
        uint256 amount;
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
        bool withdrawn;
    }
    
    mapping(address => Stake[]) public userStakes;
    
    event Staked(address indexed user, uint256 amount, uint256 lockPeriod, uint256 unlockTimestamp, uint256 stakeIndex);
    event Withdrawn(address indexed user, uint256 principal, uint256 interest, uint256 stakeIndex);
    
    function stake(uint256 _lockPeriodInDays) external payable {
        require(msg.value > 0, "Must stake a positive amount");
        require(_lockPeriodInDays > 0, "Lock period must be greater than zero");
        
        uint256 lockPeriod = _lockPeriodInDays * 1 days;
        uint256 unlockTimestamp = block.timestamp + lockPeriod;
        
        userStakes[msg.sender].push(Stake({
            amount: msg.value,
            lockTimestamp: block.timestamp,
            unlockTimestamp: unlockTimestamp,
            withdrawn: false
        }));
        
        uint256 stakeIndex = userStakes[msg.sender].length - 1;
        
        emit Staked(msg.sender, msg.value, lockPeriod, unlockTimestamp, stakeIndex);
    }
    
    function withdraw(uint256 _stakeIndex) external {
        require(_stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        
        Stake storage userStake = userStakes[msg.sender][_stakeIndex];
        
        require(!userStake.withdrawn, "Stake already withdrawn");
        require(block.timestamp >= userStake.unlockTimestamp, "Stake is still locked");
        
        uint256 principal = userStake.amount;
        uint256 lockDuration = userStake.unlockTimestamp - userStake.lockTimestamp;
        uint256 interest = (principal * INTEREST_RATE * lockDuration) / (SECONDS_PER_YEAR * 100);
        uint256 totalAmount = principal + interest;
        
        userStake.withdrawn = true;
        
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, principal, interest, _stakeIndex);
    }
    
    function calculateInterest(address _user, uint256 _stakeIndex) external view returns (uint256) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        Stake memory userStake = userStakes[_user][_stakeIndex];
        
        if (userStake.withdrawn) {
            return 0;
        }
        
        uint256 lockDuration = userStake.unlockTimestamp - userStake.lockTimestamp;
        uint256 interest = (userStake.amount * INTEREST_RATE * lockDuration) / (SECONDS_PER_YEAR * 100);
        
        return interest;
    }
    
    function getStakeInfo(address _user, uint256 _stakeIndex) external view returns (
        uint256 amount,
        uint256 lockTimestamp,
        uint256 unlockTimestamp,
        bool withdrawn,
        uint256 interest
    ) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        Stake memory userStake = userStakes[_user][_stakeIndex];
        
        uint256 lockDuration = userStake.unlockTimestamp - userStake.lockTimestamp;
        uint256 calculatedInterest = (userStake.amount * INTEREST_RATE * lockDuration) / (SECONDS_PER_YEAR * 100);
        
        return (
            userStake.amount,
            userStake.lockTimestamp,
            userStake.unlockTimestamp,
            userStake.withdrawn,
            calculatedInterest
        );
    }
    
    function getUserStakeCount(address _user) external view returns (uint256) {
        return userStakes[_user].length;
    }
    
    function timeUntilUnlock(address _user, uint256 _stakeIndex) external view returns (uint256) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        Stake memory userStake = userStakes[_user][_stakeIndex];
        
        if (block.timestamp >= userStake.unlockTimestamp) {
            return 0;
        }
        
        return userStake.unlockTimestamp - block.timestamp;
    }
    
    receive() external payable {}
}
