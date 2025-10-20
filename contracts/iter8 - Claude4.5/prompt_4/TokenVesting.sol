// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenVesting
 * @dev Token vesting contract where tokens are released gradually over time to beneficiaries
 */
contract TokenVesting {
    // Vesting schedule structure
    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
        uint256 releasedAmount;
        bool revoked;
        bool exists;
    }

    // State variables
    address public owner;
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public hasBeneficiary;
    address[] public beneficiaries;
    
    uint256 public totalVestedAmount;
    uint256 public totalReleasedAmount;

    // Events
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    event TokensReleased(address indexed beneficiary, uint256 amount, uint256 timestamp);
    event VestingRevoked(address indexed beneficiary, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier hasBeneficiarySchedule(address beneficiary) {
        require(hasBeneficiary[beneficiary], "No vesting schedule for this beneficiary");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a vesting schedule for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @param amount Total amount to vest
     * @param startTime Start time of vesting
     * @param durationInDays Duration of vesting in days
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 durationInDays
    ) public payable onlyOwner {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value == amount, "Must send exact vesting amount");
        require(durationInDays > 0, "Duration must be greater than 0");
        require(!hasBeneficiary[beneficiary], "Beneficiary already has a vesting schedule");
        require(startTime >= block.timestamp, "Start time must be in the future or now");

        uint256 duration = durationInDays * 1 days;

        vestingSchedules[beneficiary] = VestingSchedule({
            beneficiary: beneficiary,
            totalAmount: amount,
            startTime: startTime,
            duration: duration,
            releasedAmount: 0,
            revoked: false,
            exists: true
        });

        hasBeneficiary[beneficiary] = true;
        beneficiaries.push(beneficiary);
        totalVestedAmount += amount;

        emit VestingScheduleCreated(beneficiary, amount, startTime, duration);
    }

    /**
     * @dev Release vested tokens to the beneficiary
     */
    function release() public hasBeneficiarySchedule(msg.sender) {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(!schedule.revoked, "Vesting has been revoked");

        uint256 vestedAmount = _vestedAmount(msg.sender);
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;

        require(releasableAmount > 0, "No tokens available for release");

        schedule.releasedAmount += releasableAmount;
        totalReleasedAmount += releasableAmount;

        payable(msg.sender).transfer(releasableAmount);

        emit TokensReleased(msg.sender, releasableAmount, block.timestamp);
    }

    /**
     * @dev Revoke vesting schedule (only owner)
     * @param beneficiary Address of the beneficiary
     */
    function revokeVesting(address beneficiary) public onlyOwner hasBeneficiarySchedule(beneficiary) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(!schedule.revoked, "Vesting already revoked");

        uint256 vestedAmount = _vestedAmount(beneficiary);
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;

        schedule.revoked = true;

        if (releasableAmount > 0) {
            schedule.releasedAmount += releasableAmount;
            totalReleasedAmount += releasableAmount;
            payable(beneficiary).transfer(releasableAmount);
            emit TokensReleased(beneficiary, releasableAmount, block.timestamp);
        }

        // Return unvested amount to owner
        uint256 unvestedAmount = schedule.totalAmount - vestedAmount;
        if (unvestedAmount > 0) {
            payable(owner).transfer(unvestedAmount);
        }

        emit VestingRevoked(beneficiary, block.timestamp);
    }

    /**
     * @dev Calculate vested amount for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return Vested amount
     */
    function _vestedAmount(address beneficiary) private view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];

        if (block.timestamp < schedule.startTime) {
            return 0;
        } else if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.totalAmount;
        } else {
            uint256 timeElapsed = block.timestamp - schedule.startTime;
            return (schedule.totalAmount * timeElapsed) / schedule.duration;
        }
    }

    /**
     * @dev Get vested amount for a beneficiary (public view)
     * @param beneficiary Address of the beneficiary
     * @return Vested amount
     */
    function vestedAmount(address beneficiary) public view hasBeneficiarySchedule(beneficiary) returns (uint256) {
        return _vestedAmount(beneficiary);
    }

    /**
     * @dev Get releasable amount for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return Releasable amount
     */
    function releasableAmount(address beneficiary) public view hasBeneficiarySchedule(beneficiary) returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        if (schedule.revoked) {
            return 0;
        }
        uint256 vested = _vestedAmount(beneficiary);
        return vested - schedule.releasedAmount;
    }

    /**
     * @dev Get releasable amount for caller
     * @return Releasable amount
     */
    function getMyReleasableAmount() public view returns (uint256) {
        if (!hasBeneficiary[msg.sender]) {
            return 0;
        }
        return releasableAmount(msg.sender);
    }

    /**
     * @dev Get vesting schedule details
     * @param beneficiary Address of the beneficiary
     * @return totalAmount Total vesting amount
     * @return startTime Vesting start time
     * @return duration Vesting duration
     * @return releasedAmount Amount already released
     * @return revoked Whether vesting is revoked
     */
    function getVestingSchedule(address beneficiary)
        public
        view
        hasBeneficiarySchedule(beneficiary)
        returns (
            uint256 totalAmount,
            uint256 startTime,
            uint256 duration,
            uint256 releasedAmount,
            bool revoked
        )
    {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        return (
            schedule.totalAmount,
            schedule.startTime,
            schedule.duration,
            schedule.releasedAmount,
            schedule.revoked
        );
    }

    /**
     * @dev Get all beneficiaries
     * @return Array of beneficiary addresses
     */
    function getAllBeneficiaries() public view returns (address[] memory) {
        return beneficiaries;
    }

    /**
     * @dev Get total number of beneficiaries
     * @return Total beneficiary count
     */
    function getBeneficiaryCount() public view returns (uint256) {
        return beneficiaries.length;
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get vesting progress percentage (in basis points, 10000 = 100%)
     * @param beneficiary Address of the beneficiary
     * @return Progress percentage
     */
    function getVestingProgress(address beneficiary) 
        public 
        view 
        hasBeneficiarySchedule(beneficiary) 
        returns (uint256) 
    {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0) return 0;
        return (_vestedAmount(beneficiary) * 10000) / schedule.totalAmount;
    }

    /**
     * @dev Check if vesting has started for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return true if started
     */
    function hasVestingStarted(address beneficiary) 
        public 
        view 
        hasBeneficiarySchedule(beneficiary) 
        returns (bool) 
    {
        return block.timestamp >= vestingSchedules[beneficiary].startTime;
    }

    /**
     * @dev Check if vesting is complete for a beneficiary
     * @param beneficiary Address of the beneficiary
     * @return true if complete
     */
    function isVestingComplete(address beneficiary) 
        public 
        view 
        hasBeneficiarySchedule(beneficiary) 
        returns (bool) 
    {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        return block.timestamp >= schedule.startTime + schedule.duration;
    }

    /**
     * @dev Get time remaining until vesting completion
     * @param beneficiary Address of the beneficiary
     * @return Seconds remaining (0 if complete)
     */
    function getTimeRemaining(address beneficiary) 
        public 
        view 
        hasBeneficiarySchedule(beneficiary) 
        returns (uint256) 
    {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        uint256 endTime = schedule.startTime + schedule.duration;
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
