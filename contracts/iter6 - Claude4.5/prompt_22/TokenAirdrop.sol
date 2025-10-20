// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenAirdrop
 * @dev A contract for token airdrop that distributes tokens (ETH) to a predefined list of addresses
 */
contract TokenAirdrop {
    address public owner;
    
    struct Airdrop {
        uint256 id;
        string name;
        uint256 amountPerRecipient;
        address[] recipients;
        mapping(address => bool) hasClaimed;
        mapping(address => bool) isEligible;
        uint256 totalDistributed;
        uint256 claimCount;
        bool isActive;
        uint256 createdAt;
        uint256 expiresAt;
    }
    
    uint256 public airdropCount;
    mapping(uint256 => Airdrop) public airdrops;
    
    // Events
    event AirdropCreated(uint256 indexed airdropId, string name, uint256 amountPerRecipient, uint256 recipientCount);
    event TokensClaimed(uint256 indexed airdropId, address indexed recipient, uint256 amount);
    event AirdropClosed(uint256 indexed airdropId);
    event AirdropFunded(uint256 indexed airdropId, address indexed funder, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new airdrop
     * @param name The name of the airdrop
     * @param amountPerRecipient The amount each recipient will receive
     * @param recipients Array of recipient addresses
     * @param durationInDays Duration of the airdrop in days (0 for no expiry)
     */
    function createAirdrop(
        string memory name,
        uint256 amountPerRecipient,
        address[] memory recipients,
        uint256 durationInDays
    ) external payable onlyOwner {
        require(bytes(name).length > 0, "Airdrop name cannot be empty");
        require(amountPerRecipient > 0, "Amount per recipient must be greater than 0");
        require(recipients.length > 0, "Recipients list cannot be empty");
        
        uint256 totalRequired = amountPerRecipient * recipients.length;
        require(msg.value >= totalRequired, "Insufficient funds for airdrop");
        
        airdropCount++;
        Airdrop storage newAirdrop = airdrops[airdropCount];
        
        newAirdrop.id = airdropCount;
        newAirdrop.name = name;
        newAirdrop.amountPerRecipient = amountPerRecipient;
        newAirdrop.isActive = true;
        newAirdrop.createdAt = block.timestamp;
        newAirdrop.expiresAt = durationInDays > 0 ? block.timestamp + (durationInDays * 1 days) : 0;
        
        // Add recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            
            if (!newAirdrop.isEligible[recipients[i]]) {
                newAirdrop.recipients.push(recipients[i]);
                newAirdrop.isEligible[recipients[i]] = true;
            }
        }
        
        emit AirdropCreated(airdropCount, name, amountPerRecipient, newAirdrop.recipients.length);
    }
    
    /**
     * @dev Claim tokens from an airdrop
     * @param airdropId The ID of the airdrop
     */
    function claimTokens(uint256 airdropId) external {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        Airdrop storage airdrop = airdrops[airdropId];
        
        require(airdrop.isActive, "Airdrop is not active");
        require(airdrop.expiresAt == 0 || block.timestamp <= airdrop.expiresAt, "Airdrop has expired");
        require(airdrop.isEligible[msg.sender], "Not eligible for this airdrop");
        require(!airdrop.hasClaimed[msg.sender], "Already claimed");
        require(address(this).balance >= airdrop.amountPerRecipient, "Insufficient contract balance");
        
        airdrop.hasClaimed[msg.sender] = true;
        airdrop.totalDistributed += airdrop.amountPerRecipient;
        airdrop.claimCount++;
        
        (bool success, ) = msg.sender.call{value: airdrop.amountPerRecipient}("");
        require(success, "Transfer failed");
        
        emit TokensClaimed(airdropId, msg.sender, airdrop.amountPerRecipient);
    }
    
    /**
     * @dev Batch distribute tokens to all recipients (owner only)
     * @param airdropId The ID of the airdrop
     */
    function batchDistribute(uint256 airdropId) external onlyOwner {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        Airdrop storage airdrop = airdrops[airdropId];
        
        require(airdrop.isActive, "Airdrop is not active");
        
        uint256 distributed = 0;
        for (uint256 i = 0; i < airdrop.recipients.length; i++) {
            address recipient = airdrop.recipients[i];
            
            if (!airdrop.hasClaimed[recipient]) {
                airdrop.hasClaimed[recipient] = true;
                airdrop.claimCount++;
                
                (bool success, ) = recipient.call{value: airdrop.amountPerRecipient}("");
                if (success) {
                    distributed += airdrop.amountPerRecipient;
                    emit TokensClaimed(airdropId, recipient, airdrop.amountPerRecipient);
                }
            }
        }
        
        airdrop.totalDistributed += distributed;
    }
    
    /**
     * @dev Close an airdrop and refund remaining funds
     * @param airdropId The ID of the airdrop
     */
    function closeAirdrop(uint256 airdropId) external onlyOwner {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        Airdrop storage airdrop = airdrops[airdropId];
        
        require(airdrop.isActive, "Airdrop is already closed");
        
        airdrop.isActive = false;
        
        emit AirdropClosed(airdropId);
    }
    
    /**
     * @dev Get airdrop details
     * @param airdropId The ID of the airdrop
     * @return id Airdrop ID
     * @return name Airdrop name
     * @return amountPerRecipient Amount per recipient
     * @return recipientCount Total number of recipients
     * @return totalDistributed Total amount distributed
     * @return claimCount Number of claims
     * @return isActive Whether the airdrop is active
     * @return createdAt Creation timestamp
     * @return expiresAt Expiration timestamp
     */
    function getAirdrop(uint256 airdropId) external view returns (
        uint256 id,
        string memory name,
        uint256 amountPerRecipient,
        uint256 recipientCount,
        uint256 totalDistributed,
        uint256 claimCount,
        bool isActive,
        uint256 createdAt,
        uint256 expiresAt
    ) {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        Airdrop storage airdrop = airdrops[airdropId];
        
        return (
            airdrop.id,
            airdrop.name,
            airdrop.amountPerRecipient,
            airdrop.recipients.length,
            airdrop.totalDistributed,
            airdrop.claimCount,
            airdrop.isActive,
            airdrop.createdAt,
            airdrop.expiresAt
        );
    }
    
    /**
     * @dev Get all recipients for an airdrop
     * @param airdropId The ID of the airdrop
     * @return Array of recipient addresses
     */
    function getRecipients(uint256 airdropId) external view returns (address[] memory) {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        return airdrops[airdropId].recipients;
    }
    
    /**
     * @dev Check if an address is eligible for an airdrop
     * @param airdropId The ID of the airdrop
     * @param recipient The address to check
     * @return True if eligible, false otherwise
     */
    function isEligible(uint256 airdropId, address recipient) external view returns (bool) {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        return airdrops[airdropId].isEligible[recipient];
    }
    
    /**
     * @dev Check if an address has claimed from an airdrop
     * @param airdropId The ID of the airdrop
     * @param recipient The address to check
     * @return True if claimed, false otherwise
     */
    function hasClaimed(uint256 airdropId, address recipient) external view returns (bool) {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        return airdrops[airdropId].hasClaimed[recipient];
    }
    
    /**
     * @dev Get unclaimed recipients for an airdrop
     * @param airdropId The ID of the airdrop
     * @return Array of addresses that haven't claimed
     */
    function getUnclaimedRecipients(uint256 airdropId) external view returns (address[] memory) {
        require(airdropId > 0 && airdropId <= airdropCount, "Invalid airdrop ID");
        Airdrop storage airdrop = airdrops[airdropId];
        
        uint256 unclaimedCount = 0;
        for (uint256 i = 0; i < airdrop.recipients.length; i++) {
            if (!airdrop.hasClaimed[airdrop.recipients[i]]) {
                unclaimedCount++;
            }
        }
        
        address[] memory unclaimed = new address[](unclaimedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < airdrop.recipients.length; i++) {
            if (!airdrop.hasClaimed[airdrop.recipients[i]]) {
                unclaimed[index] = airdrop.recipients[i];
                index++;
            }
        }
        
        return unclaimed;
    }
    
    /**
     * @dev Get all active airdrops
     * @return Array of active airdrop IDs
     */
    function getActiveAirdrops() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= airdropCount; i++) {
            if (airdrops[i].isActive) {
                activeCount++;
            }
        }
        
        uint256[] memory activeAirdrops = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= airdropCount; i++) {
            if (airdrops[i].isActive) {
                activeAirdrops[index] = i;
                index++;
            }
        }
        
        return activeAirdrops;
    }
    
    /**
     * @dev Get airdrops the caller is eligible for
     * @return Array of airdrop IDs
     */
    function getMyEligibleAirdrops() external view returns (uint256[] memory) {
        uint256 eligibleCount = 0;
        
        for (uint256 i = 1; i <= airdropCount; i++) {
            if (airdrops[i].isEligible[msg.sender] && airdrops[i].isActive && !airdrops[i].hasClaimed[msg.sender]) {
                eligibleCount++;
            }
        }
        
        uint256[] memory eligible = new uint256[](eligibleCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= airdropCount; i++) {
            if (airdrops[i].isEligible[msg.sender] && airdrops[i].isActive && !airdrops[i].hasClaimed[msg.sender]) {
                eligible[index] = i;
                index++;
            }
        }
        
        return eligible;
    }
    
    /**
     * @dev Fund the contract for airdrops
     */
    function fundContract() external payable {
        require(msg.value > 0, "Must send some ETH");
    }
    
    /**
     * @dev Withdraw excess funds (owner only)
     * @param amount Amount to withdraw
     */
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Get contract balance
     * @return The contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership
     * @param newOwner The new owner's address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}
}
