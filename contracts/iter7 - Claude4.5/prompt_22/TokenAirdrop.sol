// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenAirdrop
 * @dev A contract for token airdrop that distributes tokens to a predefined list of addresses
 */
contract TokenAirdrop {
    address public owner;
    string public tokenName;
    string public tokenSymbol;
    uint256 public totalSupply;
    
    // Token balances
    mapping(address => uint256) public balances;
    
    // Airdrop campaign structure
    struct AirdropCampaign {
        uint256 id;
        string name;
        uint256 amountPerRecipient;
        bool completed;
        uint256 totalDistributed;
        uint256 recipientCount;
        uint256 createdAt;
    }
    
    // State variables
    uint256 public campaignCount;
    mapping(uint256 => AirdropCampaign) public campaigns;
    mapping(uint256 => mapping(address => bool)) public hasReceived;
    mapping(uint256 => address[]) public campaignRecipients;
    
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event AirdropCampaignCreated(uint256 indexed campaignId, string name, uint256 amountPerRecipient);
    event AirdropExecuted(uint256 indexed campaignId, address indexed recipient, uint256 amount);
    event AirdropCampaignCompleted(uint256 indexed campaignId, uint256 totalDistributed, uint256 recipientCount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /**
     * @dev Constructor to initialize the token
     * @param _tokenName The name of the token
     * @param _tokenSymbol The symbol of the token
     * @param _initialSupply The initial supply of tokens
     */
    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _initialSupply) {
        require(_initialSupply > 0, "Initial supply must be greater than 0");
        
        owner = msg.sender;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        totalSupply = _initialSupply;
        balances[owner] = _initialSupply;
        
        emit TokensMinted(owner, _initialSupply);
    }
    
    /**
     * @dev Create a new airdrop campaign
     * @param name The name of the campaign
     * @param recipients The list of recipient addresses
     * @param amountPerRecipient The amount each recipient will receive
     * @return campaignId The ID of the created campaign
     */
    function createAirdropCampaign(
        string memory name,
        address[] memory recipients,
        uint256 amountPerRecipient
    ) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "Campaign name cannot be empty");
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(amountPerRecipient > 0, "Amount per recipient must be greater than 0");
        
        // Calculate total needed
        uint256 totalNeeded = amountPerRecipient * recipients.length;
        require(balances[owner] >= totalNeeded, "Insufficient balance for airdrop");
        
        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
        }
        
        campaignCount++;
        uint256 campaignId = campaignCount;
        
        campaigns[campaignId] = AirdropCampaign({
            id: campaignId,
            name: name,
            amountPerRecipient: amountPerRecipient,
            completed: false,
            totalDistributed: 0,
            recipientCount: 0,
            createdAt: block.timestamp
        });
        
        // Store recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            campaignRecipients[campaignId].push(recipients[i]);
        }
        
        emit AirdropCampaignCreated(campaignId, name, amountPerRecipient);
        
        return campaignId;
    }
    
    /**
     * @dev Execute airdrop for a campaign
     * @param campaignId The ID of the campaign
     */
    function executeAirdrop(uint256 campaignId) external onlyOwner {
        require(campaignId > 0 && campaignId <= campaignCount, "Invalid campaign ID");
        AirdropCampaign storage campaign = campaigns[campaignId];
        
        require(!campaign.completed, "Campaign already completed");
        
        address[] memory recipients = campaignRecipients[campaignId];
        uint256 amount = campaign.amountPerRecipient;
        
        // Execute airdrop
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            
            if (!hasReceived[campaignId][recipient]) {
                balances[owner] -= amount;
                balances[recipient] += amount;
                hasReceived[campaignId][recipient] = true;
                
                campaign.totalDistributed += amount;
                campaign.recipientCount++;
                
                emit AirdropExecuted(campaignId, recipient, amount);
            }
        }
        
        campaign.completed = true;
        
        emit AirdropCampaignCompleted(campaignId, campaign.totalDistributed, campaign.recipientCount);
    }
    
    /**
     * @dev Execute airdrop for specific recipients in a campaign
     * @param campaignId The ID of the campaign
     * @param recipients The list of recipients to airdrop to
     */
    function executePartialAirdrop(uint256 campaignId, address[] memory recipients) external onlyOwner {
        require(campaignId > 0 && campaignId <= campaignCount, "Invalid campaign ID");
        AirdropCampaign storage campaign = campaigns[campaignId];
        
        require(!campaign.completed, "Campaign already completed");
        require(recipients.length > 0, "Recipients list cannot be empty");
        
        uint256 amount = campaign.amountPerRecipient;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            require(recipient != address(0), "Invalid recipient address");
            
            if (!hasReceived[campaignId][recipient]) {
                require(balances[owner] >= amount, "Insufficient balance");
                
                balances[owner] -= amount;
                balances[recipient] += amount;
                hasReceived[campaignId][recipient] = true;
                
                campaign.totalDistributed += amount;
                campaign.recipientCount++;
                
                emit AirdropExecuted(campaignId, recipient, amount);
            }
        }
    }
    
    /**
     * @dev Single airdrop to one address (not part of a campaign)
     * @param recipient The recipient address
     * @param amount The amount to airdrop
     */
    function airdropSingle(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[owner] >= amount, "Insufficient balance");
        
        balances[owner] -= amount;
        balances[recipient] += amount;
        
        emit TokensTransferred(owner, recipient, amount);
    }
    
    /**
     * @dev Batch airdrop to multiple addresses with different amounts
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts for each recipient
     */
    function airdropBatch(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            require(balances[owner] >= amounts[i], "Insufficient balance");
            
            balances[owner] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            
            emit TokensTransferred(owner, recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev Transfer tokens to another address
     * @param to The recipient address
     * @param amount The amount to transfer
     */
    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit TokensTransferred(msg.sender, to, amount);
    }
    
    /**
     * @dev Mint new tokens (only owner)
     * @param amount The amount to mint
     */
    function mint(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        
        totalSupply += amount;
        balances[owner] += amount;
        
        emit TokensMinted(owner, amount);
    }
    
    /**
     * @dev Get balance of an address
     * @param account The address to query
     * @return The token balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    /**
     * @dev Get campaign details
     * @param campaignId The ID of the campaign
     * @return id Campaign ID
     * @return name Campaign name
     * @return amountPerRecipient Amount per recipient
     * @return completed Whether campaign is completed
     * @return totalDistributed Total tokens distributed
     * @return recipientCount Number of recipients who received
     * @return createdAt Creation timestamp
     */
    function getCampaign(uint256 campaignId) external view returns (
        uint256 id,
        string memory name,
        uint256 amountPerRecipient,
        bool completed,
        uint256 totalDistributed,
        uint256 recipientCount,
        uint256 createdAt
    ) {
        require(campaignId > 0 && campaignId <= campaignCount, "Invalid campaign ID");
        
        AirdropCampaign memory campaign = campaigns[campaignId];
        return (
            campaign.id,
            campaign.name,
            campaign.amountPerRecipient,
            campaign.completed,
            campaign.totalDistributed,
            campaign.recipientCount,
            campaign.createdAt
        );
    }
    
    /**
     * @dev Get all recipients for a campaign
     * @param campaignId The ID of the campaign
     * @return Array of recipient addresses
     */
    function getCampaignRecipients(uint256 campaignId) external view returns (address[] memory) {
        require(campaignId > 0 && campaignId <= campaignCount, "Invalid campaign ID");
        return campaignRecipients[campaignId];
    }
    
    /**
     * @dev Check if an address has received airdrop from a campaign
     * @param campaignId The ID of the campaign
     * @param recipient The address to check
     * @return True if the address has received, false otherwise
     */
    function hasReceivedAirdrop(uint256 campaignId, address recipient) external view returns (bool) {
        require(campaignId > 0 && campaignId <= campaignCount, "Invalid campaign ID");
        return hasReceived[campaignId][recipient];
    }
    
    /**
     * @dev Get all campaigns
     * @return Array of campaign IDs
     */
    function getAllCampaigns() external view returns (uint256[] memory) {
        uint256[] memory allCampaignIds = new uint256[](campaignCount);
        
        for (uint256 i = 1; i <= campaignCount; i++) {
            allCampaignIds[i - 1] = i;
        }
        
        return allCampaignIds;
    }
    
    /**
     * @dev Get active (not completed) campaigns
     * @return Array of active campaign IDs
     */
    function getActiveCampaigns() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= campaignCount; i++) {
            if (!campaigns[i].completed) {
                activeCount++;
            }
        }
        
        uint256[] memory activeCampaignIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= campaignCount; i++) {
            if (!campaigns[i].completed) {
                activeCampaignIds[index] = i;
                index++;
            }
        }
        
        return activeCampaignIds;
    }
    
    /**
     * @dev Get caller's token balance
     * @return The caller's token balance
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}
