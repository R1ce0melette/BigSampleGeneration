// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenAirdrop {
    address public owner;
    IERC20 public token;
    
    mapping(address => uint256) public allocations;
    mapping(address => bool) public hasClaimed;
    
    uint256 public totalAllocated;
    uint256 public totalClaimed;
    uint256 public claimCount;
    
    bool public airdropActive;
    uint256 public airdropStartTime;
    uint256 public airdropEndTime;
    
    event AirdropCreated(address indexed token, uint256 totalAmount, uint256 startTime, uint256 endTime);
    event AllocationAdded(address indexed recipient, uint256 amount);
    event TokensClaimed(address indexed recipient, uint256 amount);
    event AirdropActivated(uint256 timestamp);
    event AirdropDeactivated(uint256 timestamp);
    event RemainingTokensWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier airdropIsActive() {
        require(airdropActive, "Airdrop is not active");
        require(block.timestamp >= airdropStartTime, "Airdrop has not started yet");
        require(block.timestamp <= airdropEndTime, "Airdrop has ended");
        _;
    }
    
    constructor(address _token, uint256 _startTime, uint256 _endTime) {
        require(_token != address(0), "Token address cannot be zero");
        require(_startTime < _endTime, "Start time must be before end time");
        
        owner = msg.sender;
        token = IERC20(_token);
        airdropStartTime = _startTime;
        airdropEndTime = _endTime;
        airdropActive = false;
        
        emit AirdropCreated(_token, 0, _startTime, _endTime);
    }
    
    function addAllocations(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts length mismatch");
        require(_recipients.length > 0, "No recipients provided");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient cannot be zero address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
            require(allocations[_recipients[i]] == 0, "Allocation already exists for this address");
            
            allocations[_recipients[i]] = _amounts[i];
            totalAllocated += _amounts[i];
            
            emit AllocationAdded(_recipients[i], _amounts[i]);
        }
    }
    
    function addSingleAllocation(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_amount > 0, "Amount must be greater than 0");
        require(allocations[_recipient] == 0, "Allocation already exists for this address");
        
        allocations[_recipient] = _amount;
        totalAllocated += _amount;
        
        emit AllocationAdded(_recipient, _amount);
    }
    
    function activateAirdrop() external onlyOwner {
        require(!airdropActive, "Airdrop is already active");
        require(token.balanceOf(address(this)) >= totalAllocated, "Insufficient token balance in contract");
        
        airdropActive = true;
        
        emit AirdropActivated(block.timestamp);
    }
    
    function deactivateAirdrop() external onlyOwner {
        require(airdropActive, "Airdrop is not active");
        
        airdropActive = false;
        
        emit AirdropDeactivated(block.timestamp);
    }
    
    function claim() external airdropIsActive {
        require(allocations[msg.sender] > 0, "No allocation for this address");
        require(!hasClaimed[msg.sender], "Tokens already claimed");
        
        uint256 amount = allocations[msg.sender];
        hasClaimed[msg.sender] = true;
        totalClaimed += amount;
        claimCount++;
        
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        
        emit TokensClaimed(msg.sender, amount);
    }
    
    function claimFor(address _recipient) external airdropIsActive {
        require(allocations[_recipient] > 0, "No allocation for this address");
        require(!hasClaimed[_recipient], "Tokens already claimed");
        
        uint256 amount = allocations[_recipient];
        hasClaimed[_recipient] = true;
        totalClaimed += amount;
        claimCount++;
        
        require(token.transfer(_recipient, amount), "Token transfer failed");
        
        emit TokensClaimed(_recipient, amount);
    }
    
    function batchClaim(address[] calldata _recipients) external onlyOwner airdropIsActive {
        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            
            if (allocations[recipient] > 0 && !hasClaimed[recipient]) {
                uint256 amount = allocations[recipient];
                hasClaimed[recipient] = true;
                totalClaimed += amount;
                claimCount++;
                
                require(token.transfer(recipient, amount), "Token transfer failed");
                
                emit TokensClaimed(recipient, amount);
            }
        }
    }
    
    function withdrawRemainingTokens() external onlyOwner {
        require(block.timestamp > airdropEndTime || !airdropActive, "Airdrop is still active");
        
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        require(token.transfer(owner, balance), "Token transfer failed");
        
        emit RemainingTokensWithdrawn(owner, balance);
    }
    
    function getAllocation(address _recipient) external view returns (uint256) {
        return allocations[_recipient];
    }
    
    function getClaimStatus(address _recipient) external view returns (bool) {
        return hasClaimed[_recipient];
    }
    
    function getAirdropInfo() external view returns (
        address tokenAddress,
        uint256 _totalAllocated,
        uint256 _totalClaimed,
        uint256 _claimCount,
        bool _airdropActive,
        uint256 _airdropStartTime,
        uint256 _airdropEndTime,
        uint256 contractBalance
    ) {
        return (
            address(token),
            totalAllocated,
            totalClaimed,
            claimCount,
            airdropActive,
            airdropStartTime,
            airdropEndTime,
            token.balanceOf(address(this))
        );
    }
    
    function canClaim(address _recipient) external view returns (bool) {
        return airdropActive &&
               block.timestamp >= airdropStartTime &&
               block.timestamp <= airdropEndTime &&
               allocations[_recipient] > 0 &&
               !hasClaimed[_recipient];
    }
    
    function updateAirdropTimes(uint256 _newStartTime, uint256 _newEndTime) external onlyOwner {
        require(!airdropActive, "Cannot update times while airdrop is active");
        require(_newStartTime < _newEndTime, "Start time must be before end time");
        
        airdropStartTime = _newStartTime;
        airdropEndTime = _newEndTime;
    }
}
