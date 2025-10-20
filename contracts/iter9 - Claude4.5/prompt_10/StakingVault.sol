// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingVault {
    struct Stake {
        uint256 amount;
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
        uint256 interestRate; // Interest rate in basis points (e.g., 500 = 5%)
        bool withdrawn;
    }
    
    address public owner;
    uint256 public constant BASIS_POINTS = 10000;
    
    mapping(address => Stake[]) public userStakes;
    
    // Events
    event Staked(address indexed user, uint256 stakeIndex, uint256 amount, uint256 lockPeriod, uint256 interestRate);
    event Withdrawn(address indexed user, uint256 stakeIndex, uint256 principal, uint256 interest);
    event FundsDeposited(address indexed from, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Deposit funds to the contract to pay interest
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Lock ETH for a specific period and earn interest
     * @param _lockPeriod The lock period in seconds
     */
    function stake(uint256 _lockPeriod) external payable {
        require(msg.value > 0, "Stake amount must be greater than 0");
        require(_lockPeriod > 0, "Lock period must be greater than 0");
        
        // Calculate interest rate based on lock period
        uint256 interestRate = calculateInterestRate(_lockPeriod);
        
        Stake memory newStake = Stake({
            amount: msg.value,
            lockTimestamp: block.timestamp,
            unlockTimestamp: block.timestamp + _lockPeriod,
            interestRate: interestRate,
            withdrawn: false
        });
        
        userStakes[msg.sender].push(newStake);
        
        emit Staked(msg.sender, userStakes[msg.sender].length - 1, msg.value, _lockPeriod, interestRate);
    }
    
    /**
     * @dev Withdraw staked ETH plus interest after lock period
     * @param _stakeIndex The index of the stake to withdraw
     */
    function withdraw(uint256 _stakeIndex) external {
        require(_stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        
        Stake storage userStake = userStakes[msg.sender][_stakeIndex];
        
        require(!userStake.withdrawn, "Stake already withdrawn");
        require(block.timestamp >= userStake.unlockTimestamp, "Stake is still locked");
        
        uint256 principal = userStake.amount;
        uint256 interest = (principal * userStake.interestRate) / BASIS_POINTS;
        uint256 totalAmount = principal + interest;
        
        require(address(this).balance >= totalAmount, "Insufficient contract balance");
        
        userStake.withdrawn = true;
        
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, _stakeIndex, principal, interest);
    }
    
    /**
     * @dev Calculate interest rate based on lock period
     * @param _lockPeriod The lock period in seconds
     * @return The interest rate in basis points
     */
    function calculateInterestRate(uint256 _lockPeriod) public pure returns (uint256) {
        // Interest rates based on lock period:
        // 1-7 days: 1%
        // 8-30 days: 3%
        // 31-90 days: 5%
        // 91-180 days: 8%
        // 181-365 days: 12%
        // 365+ days: 15%
        
        if (_lockPeriod < 7 days) {
            return 100; // 1%
        } else if (_lockPeriod < 30 days) {
            return 300; // 3%
        } else if (_lockPeriod < 90 days) {
            return 500; // 5%
        } else if (_lockPeriod < 180 days) {
            return 800; // 8%
        } else if (_lockPeriod < 365 days) {
            return 1200; // 12%
        } else {
            return 1500; // 15%
        }
    }
    
    /**
     * @dev Get the number of stakes for a user
     * @param _user The address of the user
     * @return The number of stakes
     */
    function getUserStakeCount(address _user) external view returns (uint256) {
        return userStakes[_user].length;
    }
    
    /**
     * @dev Get stake details
     * @param _user The address of the user
     * @param _stakeIndex The index of the stake
     * @return amount The staked amount
     * @return lockTimestamp The lock timestamp
     * @return unlockTimestamp The unlock timestamp
     * @return interestRate The interest rate
     * @return withdrawn Whether the stake has been withdrawn
     * @return interest The interest to be earned
     */
    function getStakeDetails(address _user, uint256 _stakeIndex) external view returns (
        uint256 amount,
        uint256 lockTimestamp,
        uint256 unlockTimestamp,
        uint256 interestRate,
        bool withdrawn,
        uint256 interest
    ) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        Stake memory userStake = userStakes[_user][_stakeIndex];
        uint256 calculatedInterest = (userStake.amount * userStake.interestRate) / BASIS_POINTS;
        
        return (
            userStake.amount,
            userStake.lockTimestamp,
            userStake.unlockTimestamp,
            userStake.interestRate,
            userStake.withdrawn,
            calculatedInterest
        );
    }
    
    /**
     * @dev Check if a stake is unlocked
     * @param _user The address of the user
     * @param _stakeIndex The index of the stake
     * @return True if unlocked, false otherwise
     */
    function isUnlocked(address _user, uint256 _stakeIndex) external view returns (bool) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        return block.timestamp >= userStakes[_user][_stakeIndex].unlockTimestamp;
    }
    
    /**
     * @dev Get contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Owner can withdraw excess funds (emergency function)
     * @param _amount The amount to withdraw
     */
    function ownerWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
