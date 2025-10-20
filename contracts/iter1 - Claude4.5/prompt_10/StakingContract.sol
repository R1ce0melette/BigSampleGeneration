// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingContract
 * @dev A contract that allows users to lock their ETH for a period and earn a fixed interest when unlocked
 */
contract StakingContract {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockDuration;
        uint256 interestRate; // Interest rate in basis points (e.g., 500 = 5%)
        bool withdrawn;
    }
    
    mapping(address => Stake[]) public userStakes;
    
    // Default interest rates for different lock periods (in basis points)
    uint256 public constant INTEREST_RATE_30_DAYS = 300;   // 3%
    uint256 public constant INTEREST_RATE_90_DAYS = 700;   // 7%
    uint256 public constant INTEREST_RATE_180_DAYS = 1200; // 12%
    uint256 public constant INTEREST_RATE_365_DAYS = 2000; // 20%
    
    uint256 public constant LOCK_PERIOD_30_DAYS = 30 days;
    uint256 public constant LOCK_PERIOD_90_DAYS = 90 days;
    uint256 public constant LOCK_PERIOD_180_DAYS = 180 days;
    uint256 public constant LOCK_PERIOD_365_DAYS = 365 days;
    
    address public owner;
    uint256 public totalStaked;
    uint256 public totalInterestPaid;
    
    event Staked(
        address indexed user,
        uint256 stakeId,
        uint256 amount,
        uint256 lockDuration,
        uint256 interestRate
    );
    
    event Withdrawn(
        address indexed user,
        uint256 stakeId,
        uint256 principal,
        uint256 interest,
        uint256 total
    );
    
    event FundsDeposited(address indexed from, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Stake ETH for a specific lock period
     * @param lockDuration The duration to lock the ETH (in seconds)
     */
    function stake(uint256 lockDuration) external payable {
        require(msg.value > 0, "Must stake a positive amount");
        require(_isValidLockDuration(lockDuration), "Invalid lock duration");
        
        uint256 interestRate = _getInterestRate(lockDuration);
        
        Stake memory newStake = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            lockDuration: lockDuration,
            interestRate: interestRate,
            withdrawn: false
        });
        
        userStakes[msg.sender].push(newStake);
        totalStaked += msg.value;
        
        uint256 stakeId = userStakes[msg.sender].length - 1;
        
        emit Staked(msg.sender, stakeId, msg.value, lockDuration, interestRate);
    }
    
    /**
     * @dev Withdraw staked ETH with interest after lock period
     * @param stakeId The ID of the stake to withdraw
     */
    function withdraw(uint256 stakeId) external {
        require(stakeId < userStakes[msg.sender].length, "Invalid stake ID");
        
        Stake storage userStake = userStakes[msg.sender][stakeId];
        
        require(!userStake.withdrawn, "Already withdrawn");
        require(
            block.timestamp >= userStake.startTime + userStake.lockDuration,
            "Lock period not completed"
        );
        
        uint256 principal = userStake.amount;
        uint256 interest = _calculateInterest(userStake);
        uint256 total = principal + interest;
        
        require(address(this).balance >= total, "Insufficient contract balance");
        
        userStake.withdrawn = true;
        totalStaked -= principal;
        totalInterestPaid += interest;
        
        (bool success, ) = msg.sender.call{value: total}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, stakeId, principal, interest, total);
    }
    
    /**
     * @dev Owner deposits funds to cover interest payments
     */
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Must deposit a positive amount");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Get the number of stakes for a user
     * @param user The address of the user
     * @return The number of stakes
     */
    function getUserStakeCount(address user) external view returns (uint256) {
        return userStakes[user].length;
    }
    
    /**
     * @dev Get details of a specific stake
     * @param user The address of the user
     * @param stakeId The ID of the stake
     * @return amount The staked amount
     * @return startTime When the stake started
     * @return lockDuration The lock duration
     * @return interestRate The interest rate
     * @return withdrawn Whether it has been withdrawn
     * @return unlockTime When the stake can be withdrawn
     */
    function getStakeDetails(address user, uint256 stakeId) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lockDuration,
        uint256 interestRate,
        bool withdrawn,
        uint256 unlockTime
    ) {
        require(stakeId < userStakes[user].length, "Invalid stake ID");
        
        Stake memory userStake = userStakes[user][stakeId];
        
        return (
            userStake.amount,
            userStake.startTime,
            userStake.lockDuration,
            userStake.interestRate,
            userStake.withdrawn,
            userStake.startTime + userStake.lockDuration
        );
    }
    
    /**
     * @dev Calculate the interest earned on a stake
     * @param user The address of the user
     * @param stakeId The ID of the stake
     * @return The interest amount
     */
    function calculatePendingInterest(address user, uint256 stakeId) external view returns (uint256) {
        require(stakeId < userStakes[user].length, "Invalid stake ID");
        
        Stake memory userStake = userStakes[user][stakeId];
        
        if (userStake.withdrawn) {
            return 0;
        }
        
        return _calculateInterest(userStake);
    }
    
    /**
     * @dev Get total withdrawable amount for a stake
     * @param user The address of the user
     * @param stakeId The ID of the stake
     * @return The total amount (principal + interest)
     */
    function getTotalWithdrawable(address user, uint256 stakeId) external view returns (uint256) {
        require(stakeId < userStakes[user].length, "Invalid stake ID");
        
        Stake memory userStake = userStakes[user][stakeId];
        
        if (userStake.withdrawn) {
            return 0;
        }
        
        return userStake.amount + _calculateInterest(userStake);
    }
    
    /**
     * @dev Check if a stake can be withdrawn
     * @param user The address of the user
     * @param stakeId The ID of the stake
     * @return Whether the stake can be withdrawn
     */
    function canWithdraw(address user, uint256 stakeId) external view returns (bool) {
        if (stakeId >= userStakes[user].length) {
            return false;
        }
        
        Stake memory userStake = userStakes[user][stakeId];
        
        return !userStake.withdrawn && 
               block.timestamp >= userStake.startTime + userStake.lockDuration;
    }
    
    /**
     * @dev Get all active stakes for a user
     * @param user The address of the user
     * @return Array of active stake IDs
     */
    function getActiveStakes(address user) external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active stakes
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            if (!userStakes[user][i].withdrawn) {
                activeCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeStakeIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            if (!userStakes[user][i].withdrawn) {
                activeStakeIds[index] = i;
                index++;
            }
        }
        
        return activeStakeIds;
    }
    
    /**
     * @dev Get contract statistics
     * @return _totalStaked Total currently staked
     * @return _totalInterestPaid Total interest paid out
     * @return _contractBalance Current contract balance
     */
    function getContractStats() external view returns (
        uint256 _totalStaked,
        uint256 _totalInterestPaid,
        uint256 _contractBalance
    ) {
        return (totalStaked, totalInterestPaid, address(this).balance);
    }
    
    /**
     * @dev Internal function to calculate interest
     * @param userStake The stake to calculate interest for
     * @return The interest amount
     */
    function _calculateInterest(Stake memory userStake) private pure returns (uint256) {
        return (userStake.amount * userStake.interestRate) / 10000;
    }
    
    /**
     * @dev Internal function to get interest rate based on lock duration
     * @param lockDuration The lock duration
     * @return The interest rate in basis points
     */
    function _getInterestRate(uint256 lockDuration) private pure returns (uint256) {
        if (lockDuration == LOCK_PERIOD_365_DAYS) {
            return INTEREST_RATE_365_DAYS;
        } else if (lockDuration == LOCK_PERIOD_180_DAYS) {
            return INTEREST_RATE_180_DAYS;
        } else if (lockDuration == LOCK_PERIOD_90_DAYS) {
            return INTEREST_RATE_90_DAYS;
        } else if (lockDuration == LOCK_PERIOD_30_DAYS) {
            return INTEREST_RATE_30_DAYS;
        }
        
        return 0;
    }
    
    /**
     * @dev Internal function to check if lock duration is valid
     * @param lockDuration The lock duration to check
     * @return Whether the duration is valid
     */
    function _isValidLockDuration(uint256 lockDuration) private pure returns (bool) {
        return lockDuration == LOCK_PERIOD_30_DAYS ||
               lockDuration == LOCK_PERIOD_90_DAYS ||
               lockDuration == LOCK_PERIOD_180_DAYS ||
               lockDuration == LOCK_PERIOD_365_DAYS;
    }
    
    /**
     * @dev Allow contract to receive ETH
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
