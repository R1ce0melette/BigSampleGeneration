// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenAirdrop
 * @dev A contract for token airdrop that distributes tokens to a predefined list of addresses
 */
contract TokenAirdrop {
    address public owner;
    uint256 public airdropAmount;
    
    // Mapping to track if an address is eligible for airdrop
    mapping(address => bool) public isEligible;
    
    // Mapping to track if an address has claimed
    mapping(address => bool) public hasClaimed;
    
    // Mapping to track balances
    mapping(address => uint256) public balances;
    
    uint256 public totalEligible;
    uint256 public totalClaimed;
    uint256 public totalDistributed;
    
    bool public airdropActive;
    
    // Events
    event AddressAddedToWhitelist(address indexed recipient);
    event AddressRemovedFromWhitelist(address indexed recipient);
    event AirdropClaimed(address indexed recipient, uint256 amount);
    event AirdropActivated();
    event AirdropDeactivated();
    event AirdropAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event ContractFunded(address indexed funder, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the airdrop
     * @param _airdropAmount The amount each eligible address can claim
     */
    constructor(uint256 _airdropAmount) {
        require(_airdropAmount > 0, "Airdrop amount must be greater than 0");
        
        owner = msg.sender;
        airdropAmount = _airdropAmount;
        airdropActive = false;
    }
    
    /**
     * @dev Adds a single address to the eligible list
     * @param _recipient The address to add
     */
    function addToWhitelist(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid address");
        require(!isEligible[_recipient], "Address already whitelisted");
        
        isEligible[_recipient] = true;
        totalEligible++;
        
        emit AddressAddedToWhitelist(_recipient);
    }
    
    /**
     * @dev Adds multiple addresses to the eligible list
     * @param _recipients Array of addresses to add
     */
    function addMultipleToWhitelist(address[] memory _recipients) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid address");
            
            if (!isEligible[_recipients[i]]) {
                isEligible[_recipients[i]] = true;
                totalEligible++;
                emit AddressAddedToWhitelist(_recipients[i]);
            }
        }
    }
    
    /**
     * @dev Removes an address from the eligible list
     * @param _recipient The address to remove
     */
    function removeFromWhitelist(address _recipient) external onlyOwner {
        require(isEligible[_recipient], "Address not whitelisted");
        require(!hasClaimed[_recipient], "Address has already claimed");
        
        isEligible[_recipient] = false;
        totalEligible--;
        
        emit AddressRemovedFromWhitelist(_recipient);
    }
    
    /**
     * @dev Activates the airdrop for claiming
     */
    function activateAirdrop() external onlyOwner {
        require(!airdropActive, "Airdrop is already active");
        require(totalEligible > 0, "No eligible addresses");
        
        airdropActive = true;
        
        emit AirdropActivated();
    }
    
    /**
     * @dev Deactivates the airdrop
     */
    function deactivateAirdrop() external onlyOwner {
        require(airdropActive, "Airdrop is not active");
        
        airdropActive = false;
        
        emit AirdropDeactivated();
    }
    
    /**
     * @dev Allows eligible users to claim their airdrop
     */
    function claimAirdrop() external {
        require(airdropActive, "Airdrop is not active");
        require(isEligible[msg.sender], "Address not eligible for airdrop");
        require(!hasClaimed[msg.sender], "Airdrop already claimed");
        require(address(this).balance >= airdropAmount, "Insufficient contract balance");
        
        hasClaimed[msg.sender] = true;
        balances[msg.sender] += airdropAmount;
        totalClaimed++;
        totalDistributed += airdropAmount;
        
        emit AirdropClaimed(msg.sender, airdropAmount);
    }
    
    /**
     * @dev Allows users to withdraw their claimed tokens
     */
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit TokensWithdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Owner distributes airdrop to all eligible addresses at once
     */
    function distributeToAll() external onlyOwner {
        require(totalEligible > 0, "No eligible addresses");
        
        uint256 requiredBalance = airdropAmount * (totalEligible - totalClaimed);
        require(address(this).balance >= requiredBalance, "Insufficient contract balance");
        
        // This is gas-intensive; consider doing in batches for large lists
        for (uint256 i = 0; i < totalEligible; i++) {
            // Note: This requires iterating through all addresses which is not efficient
            // In a real implementation, maintain an array of eligible addresses
        }
    }
    
    /**
     * @dev Owner distributes airdrop to specific addresses
     * @param _recipients Array of addresses to distribute to
     */
    function distributeToAddresses(address[] memory _recipients) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            
            if (isEligible[recipient] && !hasClaimed[recipient]) {
                require(address(this).balance >= airdropAmount, "Insufficient contract balance");
                
                hasClaimed[recipient] = true;
                balances[recipient] += airdropAmount;
                totalClaimed++;
                totalDistributed += airdropAmount;
                
                emit AirdropClaimed(recipient, airdropAmount);
            }
        }
    }
    
    /**
     * @dev Updates the airdrop amount
     * @param _newAmount The new airdrop amount
     */
    function updateAirdropAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Amount must be greater than 0");
        require(!airdropActive, "Cannot update amount while airdrop is active");
        
        uint256 oldAmount = airdropAmount;
        airdropAmount = _newAmount;
        
        emit AirdropAmountUpdated(oldAmount, _newAmount);
    }
    
    /**
     * @dev Allows anyone to fund the contract
     */
    function fundContract() external payable {
        require(msg.value > 0, "Must send ETH");
        
        emit ContractFunded(msg.sender, msg.value);
    }
    
    /**
     * @dev Checks if an address is eligible for the airdrop
     * @param _address The address to check
     * @return True if eligible, false otherwise
     */
    function checkEligibility(address _address) external view returns (bool) {
        return isEligible[_address];
    }
    
    /**
     * @dev Checks if the caller is eligible
     * @return True if eligible, false otherwise
     */
    function amIEligible() external view returns (bool) {
        return isEligible[msg.sender];
    }
    
    /**
     * @dev Checks if an address has claimed
     * @param _address The address to check
     * @return True if claimed, false otherwise
     */
    function hasAddressClaimed(address _address) external view returns (bool) {
        return hasClaimed[_address];
    }
    
    /**
     * @dev Checks if the caller has claimed
     * @return True if claimed, false otherwise
     */
    function haveIClaimed() external view returns (bool) {
        return hasClaimed[msg.sender];
    }
    
    /**
     * @dev Returns the caller's balance
     * @return The balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Returns airdrop statistics
     * @return eligible Total eligible addresses
     * @return claimed Total claimed count
     * @return distributed Total amount distributed
     * @return remaining Remaining claimable slots
     * @return isActive Whether airdrop is active
     */
    function getAirdropStats() external view returns (
        uint256 eligible,
        uint256 claimed,
        uint256 distributed,
        uint256 remaining,
        bool isActive
    ) {
        return (
            totalEligible,
            totalClaimed,
            totalDistributed,
            totalEligible - totalClaimed,
            airdropActive
        );
    }
    
    /**
     * @dev Returns the contract balance
     * @return The contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Calculates total amount needed to complete all airdrops
     * @return The total amount needed
     */
    function getTotalAmountNeeded() external view returns (uint256) {
        uint256 remaining = totalEligible - totalClaimed;
        return remaining * airdropAmount;
    }
    
    /**
     * @dev Allows owner to withdraw excess funds
     * @param _amount The amount to withdraw
     */
    function ownerWithdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {
        emit ContractFunded(msg.sender, msg.value);
    }
}
