// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenVesting
 * @dev A token vesting contract where tokens are released gradually over time to a beneficiary
 */
contract TokenVesting {
    // ERC20-like token functionality
    string public name = "Vesting Token";
    string public symbol = "VEST";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Vesting schedule structure
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 releasedAmount;
        bool revocable;
        bool revoked;
    }
    
    address public owner;
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    );
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     * @param _initialSupply Initial token supply
     */
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10**decimals;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    /**
     * @dev Create a vesting schedule for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @param amount Total amount of tokens to vest
     * @param cliffDuration Duration in seconds before vesting starts
     * @param vestingDuration Total vesting duration in seconds
     * @param revocable Whether the vesting can be revoked
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration,
        bool revocable
    ) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(vestingDuration > 0, "Vesting duration must be greater than 0");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting schedule already exists");
        require(balances[owner] >= amount, "Insufficient balance");
        
        balances[owner] -= amount;
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            startTime: block.timestamp,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            releasedAmount: 0,
            revocable: revocable,
            revoked: false
        });
        
        emit VestingScheduleCreated(
            beneficiary,
            amount,
            block.timestamp,
            cliffDuration,
            vestingDuration
        );
    }
    
    /**
     * @dev Release vested tokens to the beneficiary
     */
    function release() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting has been revoked");
        
        uint256 vestedAmount = _computeVestedAmount(schedule);
        uint256 releasable = vestedAmount - schedule.releasedAmount;
        
        require(releasable > 0, "No tokens available for release");
        
        schedule.releasedAmount += releasable;
        balances[msg.sender] += releasable;
        
        emit TokensReleased(msg.sender, releasable);
        emit Transfer(address(this), msg.sender, releasable);
    }
    
    /**
     * @dev Revoke a vesting schedule (only if revocable)
     * @param beneficiary Address of the beneficiary
     */
    function revoke(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(schedule.revocable, "Vesting is not revocable");
        require(!schedule.revoked, "Vesting already revoked");
        
        uint256 vestedAmount = _computeVestedAmount(schedule);
        uint256 releasable = vestedAmount - schedule.releasedAmount;
        
        if (releasable > 0) {
            schedule.releasedAmount += releasable;
            balances[beneficiary] += releasable;
            emit TokensReleased(beneficiary, releasable);
            emit Transfer(address(this), beneficiary, releasable);
        }
        
        uint256 refundAmount = schedule.totalAmount - schedule.releasedAmount;
        if (refundAmount > 0) {
            balances[owner] += refundAmount;
        }
        
        schedule.revoked = true;
        emit VestingRevoked(beneficiary);
    }
    
    /**
     * @dev Compute the vested amount for a schedule
     * @param schedule The vesting schedule
     * @return The amount of vested tokens
     */
    function _computeVestedAmount(VestingSchedule memory schedule) private view returns (uint256) {
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        } else if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount;
        } else {
            uint256 timeFromStart = block.timestamp - schedule.startTime;
            return (schedule.totalAmount * timeFromStart) / schedule.vestingDuration;
        }
    }
    
    /**
     * @dev Get the releasable amount for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return The amount of tokens that can be released
     */
    function getReleasableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }
        
        uint256 vestedAmount = _computeVestedAmount(schedule);
        return vestedAmount - schedule.releasedAmount;
    }
    
    /**
     * @dev Get vesting schedule details
     * @param beneficiary Address of the beneficiary
     */
    function getVestingSchedule(address beneficiary) external view returns (
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration,
        uint256 releasedAmount,
        bool revocable,
        bool revoked
    ) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        return (
            schedule.totalAmount,
            schedule.startTime,
            schedule.cliffDuration,
            schedule.vestingDuration,
            schedule.releasedAmount,
            schedule.revocable,
            schedule.revoked
        );
    }
    
    // ERC20 Functions
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) external view returns (uint256) {
        return allowances[_owner][spender];
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
