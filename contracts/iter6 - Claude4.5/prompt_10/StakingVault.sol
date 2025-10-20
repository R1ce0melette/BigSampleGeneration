// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingVault
 * @dev A contract that allows users to lock their ETH for a period and earn a fixed interest when unlocked
 */
contract StakingVault {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        uint256 interestRate; // Interest rate in basis points (e.g., 500 = 5%)
        bool withdrawn;
    }
    
    // Mapping from user address to their stakes array
    mapping(address => Stake[]) public userStakes;
    
    // Available lock periods (in seconds) and their corresponding interest rates (in basis points)
    mapping(uint256 => uint256) public interestRates;
    
    address public owner;
    uint256 public totalStaked;
    
    // Events
    event Staked(address indexed user, uint256 stakeIndex, uint256 amount, uint256 lockPeriod, uint256 interestRate);
    event Withdrawn(address indexed user, uint256 stakeIndex, uint256 principal, uint256 interest);
    event InterestRateUpdated(uint256 lockPeriod, uint256 interestRate);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // Initialize default interest rates for different lock periods
        // 30 days = 2% (200 basis points)
        interestRates[30 days] = 200;
        // 90 days = 5% (500 basis points)
        interestRates[90 days] = 500;
        // 180 days = 10% (1000 basis points)
        interestRates[180 days] = 1000;
        // 365 days = 20% (2000 basis points)
        interestRates[365 days] = 2000;
    }
    
    /**
     * @dev Stake ETH for a specific lock period
     * @param lockPeriod The lock period in seconds
     */
    function stake(uint256 lockPeriod) external payable {
        require(msg.value > 0, "Stake amount must be greater than 0");
        require(interestRates[lockPeriod] > 0, "Invalid lock period");
        
        Stake memory newStake = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            lockPeriod: lockPeriod,
            interestRate: interestRates[lockPeriod],
            withdrawn: false
        });
        
        userStakes[msg.sender].push(newStake);
        totalStaked += msg.value;
        
        emit Staked(msg.sender, userStakes[msg.sender].length - 1, msg.value, lockPeriod, interestRates[lockPeriod]);
    }
    
    /**
     * @dev Withdraw a stake after the lock period
     * @param stakeIndex The index of the stake to withdraw
     */
    function withdraw(uint256 stakeIndex) external {
        require(stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = userStakes[msg.sender][stakeIndex];
        
        require(!userStake.withdrawn, "Stake already withdrawn");
        require(block.timestamp >= userStake.startTime + userStake.lockPeriod, "Lock period not ended");
        
        uint256 principal = userStake.amount;
        uint256 interest = calculateInterest(principal, userStake.interestRate);
        uint256 totalAmount = principal + interest;
        
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        userStake.withdrawn = true;
        totalStaked -= principal;
        
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, stakeIndex, principal, interest);
    }
    
    /**
     * @dev Calculate interest for a stake
     * @param principal The principal amount
     * @param interestRate The interest rate in basis points
     * @return The interest amount
     */
    function calculateInterest(uint256 principal, uint256 interestRate) public pure returns (uint256) {
        return (principal * interestRate) / 10000;
    }
    
    /**
     * @dev Get the number of stakes for a user
     * @param user The address of the user
     * @return The number of stakes
     */
    function getStakeCount(address user) external view returns (uint256) {
        return userStakes[user].length;
    }
    
    /**
     * @dev Get stake details
     * @param user The address of the user
     * @param stakeIndex The index of the stake
     * @return amount The staked amount
     * @return startTime The start time
     * @return lockPeriod The lock period
     * @return interestRate The interest rate
     * @return withdrawn Whether the stake was withdrawn
     * @return unlockTime The time when the stake can be withdrawn
     * @return expectedInterest The expected interest
     */
    function getStakeDetails(address user, uint256 stakeIndex) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lockPeriod,
        uint256 interestRate,
        bool withdrawn,
        uint256 unlockTime,
        uint256 expectedInterest
    ) {
        require(stakeIndex < userStakes[user].length, "Invalid stake index");
        Stake memory userStake = userStakes[user][stakeIndex];
        
        return (
            userStake.amount,
            userStake.startTime,
            userStake.lockPeriod,
            userStake.interestRate,
            userStake.withdrawn,
            userStake.startTime + userStake.lockPeriod,
            calculateInterest(userStake.amount, userStake.interestRate)
        );
    }
    
    /**
     * @dev Get all active stakes for a user
     * @param user The address of the user
     * @return stakeIndices Array of active stake indices
     */
    function getActiveStakes(address user) external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            if (!userStakes[user][i].withdrawn) {
                activeCount++;
            }
        }
        
        uint256[] memory stakeIndices = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            if (!userStakes[user][i].withdrawn) {
                stakeIndices[index] = i;
                index++;
            }
        }
        
        return stakeIndices;
    }
    
    /**
     * @dev Check if a stake is ready to withdraw
     * @param user The address of the user
     * @param stakeIndex The index of the stake
     * @return True if the stake can be withdrawn, false otherwise
     */
    function canWithdraw(address user, uint256 stakeIndex) external view returns (bool) {
        if (stakeIndex >= userStakes[user].length) {
            return false;
        }
        
        Stake memory userStake = userStakes[user][stakeIndex];
        return !userStake.withdrawn && block.timestamp >= userStake.startTime + userStake.lockPeriod;
    }
    
    /**
     * @dev Get the remaining lock time for a stake
     * @param user The address of the user
     * @param stakeIndex The index of the stake
     * @return The remaining time in seconds, or 0 if unlocked
     */
    function getRemainingLockTime(address user, uint256 stakeIndex) external view returns (uint256) {
        require(stakeIndex < userStakes[user].length, "Invalid stake index");
        Stake memory userStake = userStakes[user][stakeIndex];
        
        if (userStake.withdrawn) {
            return 0;
        }
        
        uint256 unlockTime = userStake.startTime + userStake.lockPeriod;
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        
        return unlockTime - block.timestamp;
    }
    
    /**
     * @dev Update interest rate for a lock period (owner only)
     * @param lockPeriod The lock period in seconds
     * @param interestRate The interest rate in basis points
     */
    function updateInterestRate(uint256 lockPeriod, uint256 interestRate) external onlyOwner {
        require(interestRate <= 10000, "Interest rate cannot exceed 100%");
        interestRates[lockPeriod] = interestRate;
        
        emit InterestRateUpdated(lockPeriod, interestRate);
    }
    
    /**
     * @dev Deposit funds to the contract to pay interest (owner only)
     */
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0");
    }
    
    /**
     * @dev Get the available interest pool (contract balance minus staked amount)
     * @return The available interest pool
     */
    function getInterestPool() external view returns (uint256) {
        if (address(this).balance > totalStaked) {
            return address(this).balance - totalStaked;
        }
        return 0;
    }
}
