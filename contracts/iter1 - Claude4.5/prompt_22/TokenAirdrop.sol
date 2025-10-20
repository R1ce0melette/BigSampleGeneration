// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenAirdrop
 * @dev A contract for token airdrop that distributes tokens to a predefined list of addresses
 */
contract TokenAirdrop {
    // ERC20-like token functionality
    string public name = "Airdrop Token";
    string public symbol = "AIRDROP";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Airdrop functionality
    address public owner;
    
    mapping(address => bool) public hasClaimedAirdrop;
    mapping(address => uint256) public airdropAllocation;
    
    uint256 public totalAirdropped;
    uint256 public totalAllocated;
    address[] private eligibleAddresses;
    
    bool public airdropActive;
    uint256 public airdropStartTime;
    uint256 public airdropEndTime;
    
    event AirdropConfigured(uint256 totalAmount, uint256 recipientCount);
    event AirdropClaimed(address indexed recipient, uint256 amount);
    event AirdropDistributed(address indexed recipient, uint256 amount);
    event AirdropActivated(uint256 startTime, uint256 endTime);
    event AirdropDeactivated();
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the token and airdrop
     * @param _initialSupply Initial token supply
     */
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10**decimals;
        balances[address(this)] = totalSupply;
        
        emit Transfer(address(0), address(this), totalSupply);
    }
    
    /**
     * @dev Configure airdrop for multiple recipients with the same amount
     * @param recipients Array of recipient addresses
     * @param amountPerRecipient Amount each recipient will receive
     */
    function configureAirdrop(
        address[] memory recipients,
        uint256 amountPerRecipient
    ) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(amountPerRecipient > 0, "Amount must be greater than 0");
        
        uint256 totalRequired = recipients.length * amountPerRecipient;
        require(balances[address(this)] >= totalRequired, "Insufficient balance for airdrop");
        
        // Reset previous allocations if any
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            airdropAllocation[eligibleAddresses[i]] = 0;
            hasClaimedAirdrop[eligibleAddresses[i]] = false;
        }
        
        delete eligibleAddresses;
        totalAllocated = 0;
        
        // Set new allocations
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(airdropAllocation[recipients[i]] == 0, "Duplicate recipient");
            
            airdropAllocation[recipients[i]] = amountPerRecipient;
            eligibleAddresses.push(recipients[i]);
        }
        
        totalAllocated = totalRequired;
        
        emit AirdropConfigured(totalRequired, recipients.length);
    }
    
    /**
     * @dev Configure airdrop with custom amounts for each recipient
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts corresponding to each recipient
     */
    function configureCustomAirdrop(
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        uint256 totalRequired = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Amount must be greater than 0");
            totalRequired += amounts[i];
        }
        
        require(balances[address(this)] >= totalRequired, "Insufficient balance for airdrop");
        
        // Reset previous allocations if any
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            airdropAllocation[eligibleAddresses[i]] = 0;
            hasClaimedAirdrop[eligibleAddresses[i]] = false;
        }
        
        delete eligibleAddresses;
        totalAllocated = 0;
        
        // Set new allocations
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(airdropAllocation[recipients[i]] == 0, "Duplicate recipient");
            
            airdropAllocation[recipients[i]] = amounts[i];
            eligibleAddresses.push(recipients[i]);
        }
        
        totalAllocated = totalRequired;
        
        emit AirdropConfigured(totalRequired, recipients.length);
    }
    
    /**
     * @dev Activate the airdrop for claiming
     * @param durationInDays How long the airdrop will be active
     */
    function activateAirdrop(uint256 durationInDays) external onlyOwner {
        require(!airdropActive, "Airdrop is already active");
        require(totalAllocated > 0, "Airdrop not configured");
        require(durationInDays > 0, "Duration must be greater than 0");
        
        airdropActive = true;
        airdropStartTime = block.timestamp;
        airdropEndTime = block.timestamp + (durationInDays * 1 days);
        
        emit AirdropActivated(airdropStartTime, airdropEndTime);
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
     * @dev Claim airdrop tokens
     */
    function claimAirdrop() external {
        require(airdropActive, "Airdrop is not active");
        require(block.timestamp <= airdropEndTime, "Airdrop has ended");
        require(airdropAllocation[msg.sender] > 0, "No allocation for this address");
        require(!hasClaimedAirdrop[msg.sender], "Already claimed");
        
        uint256 amount = airdropAllocation[msg.sender];
        
        hasClaimedAirdrop[msg.sender] = true;
        totalAirdropped += amount;
        
        balances[address(this)] -= amount;
        balances[msg.sender] += amount;
        
        emit Transfer(address(this), msg.sender, amount);
        emit AirdropClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Distribute airdrop to all eligible addresses (push distribution)
     */
    function distributeAirdrop() external onlyOwner {
        require(totalAllocated > 0, "Airdrop not configured");
        
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            address recipient = eligibleAddresses[i];
            
            if (!hasClaimedAirdrop[recipient] && airdropAllocation[recipient] > 0) {
                uint256 amount = airdropAllocation[recipient];
                
                hasClaimedAirdrop[recipient] = true;
                totalAirdropped += amount;
                
                balances[address(this)] -= amount;
                balances[recipient] += amount;
                
                emit Transfer(address(this), recipient, amount);
                emit AirdropDistributed(recipient, amount);
            }
        }
    }
    
    /**
     * @dev Distribute airdrop to specific addresses
     * @param recipients Array of recipient addresses to distribute to
     */
    function distributeToAddresses(address[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            
            require(airdropAllocation[recipient] > 0, "Address not eligible");
            require(!hasClaimedAirdrop[recipient], "Already claimed");
            
            uint256 amount = airdropAllocation[recipient];
            
            hasClaimedAirdrop[recipient] = true;
            totalAirdropped += amount;
            
            balances[address(this)] -= amount;
            balances[recipient] += amount;
            
            emit Transfer(address(this), recipient, amount);
            emit AirdropDistributed(recipient, amount);
        }
    }
    
    /**
     * @dev Get airdrop allocation for an address
     * @param recipient The address to check
     * @return The allocated amount
     */
    function getAllocation(address recipient) external view returns (uint256) {
        return airdropAllocation[recipient];
    }
    
    /**
     * @dev Check if an address has claimed
     * @param recipient The address to check
     * @return Whether the address has claimed
     */
    function hasClaimed(address recipient) external view returns (bool) {
        return hasClaimedAirdrop[recipient];
    }
    
    /**
     * @dev Get all eligible addresses
     * @return Array of eligible addresses
     */
    function getEligibleAddresses() external view returns (address[] memory) {
        return eligibleAddresses;
    }
    
    /**
     * @dev Get unclaimed addresses
     * @return Array of addresses that haven't claimed yet
     */
    function getUnclaimedAddresses() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count unclaimed
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (!hasClaimedAirdrop[eligibleAddresses[i]]) {
                count++;
            }
        }
        
        // Create array and populate
        address[] memory unclaimed = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (!hasClaimedAirdrop[eligibleAddresses[i]]) {
                unclaimed[index] = eligibleAddresses[i];
                index++;
            }
        }
        
        return unclaimed;
    }
    
    /**
     * @dev Get airdrop statistics
     * @return _totalAllocated Total tokens allocated
     * @return _totalAirdropped Total tokens claimed/distributed
     * @return _remainingAllocation Remaining allocation
     * @return _eligibleCount Number of eligible addresses
     * @return _claimedCount Number of addresses that claimed
     */
    function getAirdropStats() external view returns (
        uint256 _totalAllocated,
        uint256 _totalAirdropped,
        uint256 _remainingAllocation,
        uint256 _eligibleCount,
        uint256 _claimedCount
    ) {
        uint256 claimedCount = 0;
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (hasClaimedAirdrop[eligibleAddresses[i]]) {
                claimedCount++;
            }
        }
        
        return (
            totalAllocated,
            totalAirdropped,
            totalAllocated - totalAirdropped,
            eligibleAddresses.length,
            claimedCount
        );
    }
    
    /**
     * @dev Withdraw remaining tokens after airdrop
     * @param amount Amount to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[address(this)] >= amount, "Insufficient balance");
        
        balances[address(this)] -= amount;
        balances[owner] += amount;
        
        emit Transfer(address(this), owner, amount);
    }
    
    /**
     * @dev Transfer ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
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
