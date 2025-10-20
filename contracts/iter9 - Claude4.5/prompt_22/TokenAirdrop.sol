// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
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
    
    // Events
    event AirdropConfigured(address indexed tokenAddress, uint256 totalAllocated);
    event AllocationSet(address indexed recipient, uint256 amount);
    event TokensClaimed(address indexed recipient, uint256 amount);
    event AirdropActivated();
    event AirdropDeactivated();
    event TokensWithdrawn(address indexed to, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        
        owner = msg.sender;
        token = IERC20(_token);
        airdropActive = false;
    }
    
    /**
     * @dev Set allocation for a single recipient
     * @param _recipient The recipient address
     * @param _amount The amount to allocate
     */
    function setAllocation(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(!hasClaimed[_recipient], "Recipient has already claimed");
        
        // Update total allocated
        if (allocations[_recipient] > 0) {
            totalAllocated = totalAllocated - allocations[_recipient] + _amount;
        } else {
            totalAllocated += _amount;
        }
        
        allocations[_recipient] = _amount;
        
        emit AllocationSet(_recipient, _amount);
    }
    
    /**
     * @dev Set allocations for multiple recipients
     * @param _recipients Array of recipient addresses
     * @param _amounts Array of amounts corresponding to each recipient
     */
    function setAllocations(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        require(_recipients.length > 0, "Arrays cannot be empty");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
            require(!hasClaimed[_recipients[i]], "Recipient has already claimed");
            
            // Update total allocated
            if (allocations[_recipients[i]] > 0) {
                totalAllocated = totalAllocated - allocations[_recipients[i]] + _amounts[i];
            } else {
                totalAllocated += _amounts[i];
            }
            
            allocations[_recipients[i]] = _amounts[i];
            
            emit AllocationSet(_recipients[i], _amounts[i]);
        }
    }
    
    /**
     * @dev Activate the airdrop
     */
    function activateAirdrop() external onlyOwner {
        require(!airdropActive, "Airdrop is already active");
        require(totalAllocated > 0, "No allocations set");
        require(token.balanceOf(address(this)) >= totalAllocated, "Insufficient token balance");
        
        airdropActive = true;
        
        emit AirdropActivated();
    }
    
    /**
     * @dev Deactivate the airdrop
     */
    function deactivateAirdrop() external onlyOwner {
        require(airdropActive, "Airdrop is not active");
        
        airdropActive = false;
        
        emit AirdropDeactivated();
    }
    
    /**
     * @dev Claim allocated tokens
     */
    function claim() external {
        require(airdropActive, "Airdrop is not active");
        require(allocations[msg.sender] > 0, "No allocation for this address");
        require(!hasClaimed[msg.sender], "Already claimed");
        
        uint256 amount = allocations[msg.sender];
        hasClaimed[msg.sender] = true;
        totalClaimed += amount;
        claimCount++;
        
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        
        emit TokensClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Owner can distribute tokens to a recipient directly
     * @param _recipient The recipient address
     */
    function distributeTo(address _recipient) external onlyOwner {
        require(allocations[_recipient] > 0, "No allocation for this address");
        require(!hasClaimed[_recipient], "Already claimed");
        
        uint256 amount = allocations[_recipient];
        hasClaimed[_recipient] = true;
        totalClaimed += amount;
        claimCount++;
        
        require(token.transfer(_recipient, amount), "Token transfer failed");
        
        emit TokensClaimed(_recipient, amount);
    }
    
    /**
     * @dev Distribute tokens to multiple recipients
     * @param _recipients Array of recipient addresses
     */
    function distributeToMultiple(address[] memory _recipients) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        
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
    
    /**
     * @dev Check if an address can claim
     * @param _address The address to check
     * @return True if can claim, false otherwise
     */
    function canClaim(address _address) external view returns (bool) {
        return airdropActive && allocations[_address] > 0 && !hasClaimed[_address];
    }
    
    /**
     * @dev Get allocation for an address
     * @param _address The address to check
     * @return The allocated amount
     */
    function getAllocation(address _address) external view returns (uint256) {
        return allocations[_address];
    }
    
    /**
     * @dev Check if an address has claimed
     * @param _address The address to check
     * @return True if claimed, false otherwise
     */
    function hasAddressClaimed(address _address) external view returns (bool) {
        return hasClaimed[_address];
    }
    
    /**
     * @dev Get airdrop statistics
     * @return _totalAllocated Total tokens allocated
     * @return _totalClaimed Total tokens claimed
     * @return _claimCount Number of claims
     * @return _remaining Remaining tokens to be claimed
     * @return _isActive Whether the airdrop is active
     */
    function getAirdropStats() external view returns (
        uint256 _totalAllocated,
        uint256 _totalClaimed,
        uint256 _claimCount,
        uint256 _remaining,
        bool _isActive
    ) {
        return (
            totalAllocated,
            totalClaimed,
            claimCount,
            totalAllocated - totalClaimed,
            airdropActive
        );
    }
    
    /**
     * @dev Get contract token balance
     * @return The token balance
     */
    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    /**
     * @dev Withdraw tokens from the contract (for unclaimed or excess tokens)
     * @param _amount The amount to withdraw
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance");
        
        require(token.transfer(owner, _amount), "Token transfer failed");
        
        emit TokensWithdrawn(owner, _amount);
    }
    
    /**
     * @dev Withdraw all unclaimed tokens after airdrop is deactivated
     */
    function withdrawAllTokens() external onlyOwner {
        require(!airdropActive, "Airdrop is still active");
        
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        require(token.transfer(owner, balance), "Token transfer failed");
        
        emit TokensWithdrawn(owner, balance);
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param _newOwner The new owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        owner = _newOwner;
    }
}
