// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenAirdrop
 * @dev Contract for a token airdrop that distributes tokens to a predefined list of addresses
 */
contract TokenAirdrop {
    // Token properties
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Airdrop structure
    struct Airdrop {
        uint256 id;
        string name;
        uint256 totalAmount;
        uint256 amountPerRecipient;
        uint256 recipientCount;
        uint256 claimedCount;
        uint256 createdAt;
        uint256 expiryTime;
        bool active;
        bool completed;
    }

    // Recipient information
    struct RecipientInfo {
        bool eligible;
        bool claimed;
        uint256 amount;
        uint256 claimedAt;
    }

    // State variables
    address public owner;
    uint256 private airdropCounter;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    mapping(uint256 => Airdrop) private airdrops;
    mapping(uint256 => mapping(address => RecipientInfo)) private airdropRecipients;
    mapping(uint256 => address[]) private airdropRecipientList;
    mapping(address => uint256[]) private userAirdrops;
    
    uint256[] private allAirdropIds;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AirdropCreated(uint256 indexed airdropId, string name, uint256 recipientCount, uint256 totalAmount);
    event TokensClaimed(uint256 indexed airdropId, address indexed recipient, uint256 amount);
    event AirdropActivated(uint256 indexed airdropId);
    event AirdropDeactivated(uint256 indexed airdropId);
    event AirdropCompleted(uint256 indexed airdropId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier airdropExists(uint256 airdropId) {
        require(airdropId > 0 && airdropId <= airdropCounter, "Airdrop does not exist");
        _;
    }

    modifier airdropActive(uint256 airdropId) {
        require(airdrops[airdropId].active, "Airdrop is not active");
        require(block.timestamp < airdrops[airdropId].expiryTime, "Airdrop has expired");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        airdropCounter = 0;

        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /**
     * @dev Create a new airdrop
     * @param airdropName Airdrop name
     * @param recipients Array of recipient addresses
     * @param amountPerRecipient Amount of tokens per recipient
     * @param expiryTime Expiry timestamp for the airdrop
     * @return airdropId ID of the created airdrop
     */
    function createAirdrop(
        string memory airdropName,
        address[] memory recipients,
        uint256 amountPerRecipient,
        uint256 expiryTime
    ) public onlyOwner returns (uint256) {
        require(recipients.length > 0, "No recipients provided");
        require(amountPerRecipient > 0, "Amount must be greater than 0");
        require(expiryTime > block.timestamp, "Expiry time must be in the future");

        // Validate recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
        }

        uint256 totalAmount = amountPerRecipient * recipients.length;
        require(balances[owner] >= totalAmount, "Insufficient balance for airdrop");

        airdropCounter++;
        uint256 airdropId = airdropCounter;

        // Create airdrop
        Airdrop storage newAirdrop = airdrops[airdropId];
        newAirdrop.id = airdropId;
        newAirdrop.name = airdropName;
        newAirdrop.totalAmount = totalAmount;
        newAirdrop.amountPerRecipient = amountPerRecipient;
        newAirdrop.recipientCount = recipients.length;
        newAirdrop.claimedCount = 0;
        newAirdrop.createdAt = block.timestamp;
        newAirdrop.expiryTime = expiryTime;
        newAirdrop.active = true;
        newAirdrop.completed = false;

        // Lock tokens for airdrop
        balances[owner] -= totalAmount;
        balances[address(this)] += totalAmount;

        // Set up recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            airdropRecipients[airdropId][recipients[i]] = RecipientInfo({
                eligible: true,
                claimed: false,
                amount: amountPerRecipient,
                claimedAt: 0
            });
            airdropRecipientList[airdropId].push(recipients[i]);
            userAirdrops[recipients[i]].push(airdropId);
        }

        allAirdropIds.push(airdropId);

        emit Transfer(owner, address(this), totalAmount);
        emit AirdropCreated(airdropId, airdropName, recipients.length, totalAmount);

        return airdropId;
    }

    /**
     * @dev Claim tokens from an airdrop
     * @param airdropId Airdrop ID
     */
    function claimAirdrop(uint256 airdropId) 
        public 
        airdropExists(airdropId)
        airdropActive(airdropId)
    {
        RecipientInfo storage recipient = airdropRecipients[airdropId][msg.sender];
        
        require(recipient.eligible, "Not eligible for this airdrop");
        require(!recipient.claimed, "Already claimed");

        recipient.claimed = true;
        recipient.claimedAt = block.timestamp;

        airdrops[airdropId].claimedCount++;

        // Transfer tokens
        uint256 amount = recipient.amount;
        balances[address(this)] -= amount;
        balances[msg.sender] += amount;

        emit Transfer(address(this), msg.sender, amount);
        emit TokensClaimed(airdropId, msg.sender, amount);

        // Check if airdrop is completed
        if (airdrops[airdropId].claimedCount == airdrops[airdropId].recipientCount) {
            airdrops[airdropId].completed = true;
            emit AirdropCompleted(airdropId);
        }
    }

    /**
     * @dev Activate an airdrop
     * @param airdropId Airdrop ID
     */
    function activateAirdrop(uint256 airdropId) 
        public 
        onlyOwner 
        airdropExists(airdropId)
    {
        require(!airdrops[airdropId].active, "Airdrop is already active");
        airdrops[airdropId].active = true;
        emit AirdropActivated(airdropId);
    }

    /**
     * @dev Deactivate an airdrop
     * @param airdropId Airdrop ID
     */
    function deactivateAirdrop(uint256 airdropId) 
        public 
        onlyOwner 
        airdropExists(airdropId)
    {
        require(airdrops[airdropId].active, "Airdrop is already inactive");
        airdrops[airdropId].active = false;
        emit AirdropDeactivated(airdropId);
    }

    /**
     * @dev Reclaim unclaimed tokens from expired airdrop
     * @param airdropId Airdrop ID
     */
    function reclaimUnclaimedTokens(uint256 airdropId) 
        public 
        onlyOwner 
        airdropExists(airdropId)
    {
        Airdrop storage airdrop = airdrops[airdropId];
        require(block.timestamp >= airdrop.expiryTime, "Airdrop has not expired yet");
        require(!airdrop.completed, "Airdrop is already completed");

        uint256 unclaimedCount = airdrop.recipientCount - airdrop.claimedCount;
        uint256 unclaimedAmount = unclaimedCount * airdrop.amountPerRecipient;

        if (unclaimedAmount > 0) {
            balances[address(this)] -= unclaimedAmount;
            balances[owner] += unclaimedAmount;

            emit Transfer(address(this), owner, unclaimedAmount);
        }

        airdrop.completed = true;
        emit AirdropCompleted(airdropId);
    }

    /**
     * @dev Get airdrop details
     * @param airdropId Airdrop ID
     * @return Airdrop details
     */
    function getAirdrop(uint256 airdropId) 
        public 
        view 
        airdropExists(airdropId)
        returns (Airdrop memory) 
    {
        return airdrops[airdropId];
    }

    /**
     * @dev Check if address is eligible for airdrop
     * @param airdropId Airdrop ID
     * @param recipient Recipient address
     * @return true if eligible
     */
    function isEligible(uint256 airdropId, address recipient) 
        public 
        view 
        airdropExists(airdropId)
        returns (bool) 
    {
        return airdropRecipients[airdropId][recipient].eligible;
    }

    /**
     * @dev Check if address has claimed airdrop
     * @param airdropId Airdrop ID
     * @param recipient Recipient address
     * @return true if claimed
     */
    function hasClaimed(uint256 airdropId, address recipient) 
        public 
        view 
        airdropExists(airdropId)
        returns (bool) 
    {
        return airdropRecipients[airdropId][recipient].claimed;
    }

    /**
     * @dev Get recipient information
     * @param airdropId Airdrop ID
     * @param recipient Recipient address
     * @return RecipientInfo details
     */
    function getRecipientInfo(uint256 airdropId, address recipient) 
        public 
        view 
        airdropExists(airdropId)
        returns (RecipientInfo memory) 
    {
        return airdropRecipients[airdropId][recipient];
    }

    /**
     * @dev Get airdrop recipients
     * @param airdropId Airdrop ID
     * @return Array of recipient addresses
     */
    function getAirdropRecipients(uint256 airdropId) 
        public 
        view 
        airdropExists(airdropId)
        returns (address[] memory) 
    {
        return airdropRecipientList[airdropId];
    }

    /**
     * @dev Get all airdrops
     * @return Array of all airdrops
     */
    function getAllAirdrops() public view returns (Airdrop[] memory) {
        Airdrop[] memory allAirdrops = new Airdrop[](allAirdropIds.length);
        
        for (uint256 i = 0; i < allAirdropIds.length; i++) {
            allAirdrops[i] = airdrops[allAirdropIds[i]];
        }
        
        return allAirdrops;
    }

    /**
     * @dev Get active airdrops
     * @return Array of active airdrops
     */
    function getActiveAirdrops() public view returns (Airdrop[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allAirdropIds.length; i++) {
            Airdrop memory airdrop = airdrops[allAirdropIds[i]];
            if (airdrop.active && block.timestamp < airdrop.expiryTime) {
                count++;
            }
        }

        Airdrop[] memory result = new Airdrop[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allAirdropIds.length; i++) {
            Airdrop memory airdrop = airdrops[allAirdropIds[i]];
            if (airdrop.active && block.timestamp < airdrop.expiryTime) {
                result[index] = airdrop;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get user's airdrops
     * @param user User address
     * @return Array of airdrop IDs
     */
    function getUserAirdrops(address user) public view returns (uint256[] memory) {
        return userAirdrops[user];
    }

    /**
     * @dev Get user's eligible airdrops
     * @param user User address
     * @return Array of airdrops
     */
    function getUserEligibleAirdrops(address user) public view returns (Airdrop[] memory) {
        uint256[] memory airdropIds = userAirdrops[user];
        
        uint256 count = 0;
        for (uint256 i = 0; i < airdropIds.length; i++) {
            if (airdropRecipients[airdropIds[i]][user].eligible && 
                !airdropRecipients[airdropIds[i]][user].claimed) {
                count++;
            }
        }

        Airdrop[] memory result = new Airdrop[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < airdropIds.length; i++) {
            if (airdropRecipients[airdropIds[i]][user].eligible && 
                !airdropRecipients[airdropIds[i]][user].claimed) {
                result[index] = airdrops[airdropIds[i]];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total airdrop count
     * @return Total number of airdrops
     */
    function getTotalAirdropCount() public view returns (uint256) {
        return airdropCounter;
    }

    /**
     * @dev Get airdrop statistics
     * @param airdropId Airdrop ID
     * @return totalAmount Total amount allocated
     * @return claimedAmount Amount claimed
     * @return unclaimedAmount Amount unclaimed
     * @return claimPercentage Percentage claimed (scaled by 100)
     */
    function getAirdropStats(uint256 airdropId) 
        public 
        view 
        airdropExists(airdropId)
        returns (
            uint256 totalAmount,
            uint256 claimedAmount,
            uint256 unclaimedAmount,
            uint256 claimPercentage
        ) 
    {
        Airdrop memory airdrop = airdrops[airdropId];
        
        claimedAmount = airdrop.claimedCount * airdrop.amountPerRecipient;
        unclaimedAmount = airdrop.totalAmount - claimedAmount;
        claimPercentage = (airdrop.claimedCount * 10000) / airdrop.recipientCount;

        return (
            airdrop.totalAmount,
            claimedAmount,
            unclaimedAmount,
            claimPercentage
        );
    }

    /**
     * @dev Get balance of an account
     * @param account Account address
     * @return Balance of the account
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Transfer tokens
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return true if successful
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Approve spender to spend tokens
     * @param spender Spender address
     * @param amount Amount to approve
     * @return true if successful
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from another account
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return true if successful
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Get allowance
     * @param tokenOwner Token owner address
     * @param spender Spender address
     * @return Remaining allowance
     */
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    /**
     * @dev Mint new tokens (only owner)
     * @param amount Amount to mint
     */
    function mint(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");

        totalSupply += amount;
        balances[owner] += amount;

        emit Transfer(address(0), owner, amount);
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
