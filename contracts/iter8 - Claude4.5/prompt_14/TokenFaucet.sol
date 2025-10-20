// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenFaucet
 * @dev Token faucet that lets users claim a fixed amount of tokens once every 24 hours
 */
contract TokenFaucet {
    // Token properties
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Faucet properties
    uint256 public claimAmount;
    uint256 public constant CLAIM_INTERVAL = 24 hours;
    address public owner;

    // Balances and allowances
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Faucet tracking
    mapping(address => uint256) private lastClaimTime;
    mapping(address => uint256) private claimCount;
    mapping(address => bool) private hasClaimed;
    
    address[] private claimers;
    uint256 public totalClaims;
    uint256 public totalClaimedAmount;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensClaimed(address indexed claimer, uint256 amount, uint256 timestamp);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event FaucetRefilled(address indexed refiller, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier canClaim() {
        require(
            lastClaimTime[msg.sender] == 0 || 
            block.timestamp >= lastClaimTime[msg.sender] + CLAIM_INTERVAL,
            "Cannot claim yet, wait 24 hours"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _claimAmount
    ) {
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        require(_initialSupply >= _claimAmount, "Initial supply must be at least claim amount");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        claimAmount = _claimAmount;
        owner = msg.sender;

        totalSupply = _initialSupply;
        balances[address(this)] = _initialSupply;

        emit Transfer(address(0), address(this), _initialSupply);
    }

    /**
     * @dev Claim tokens from faucet
     */
    function claim() public canClaim {
        require(balances[address(this)] >= claimAmount, "Faucet is empty");

        balances[address(this)] -= claimAmount;
        balances[msg.sender] += claimAmount;

        lastClaimTime[msg.sender] = block.timestamp;
        claimCount[msg.sender]++;
        totalClaims++;
        totalClaimedAmount += claimAmount;

        if (!hasClaimed[msg.sender]) {
            hasClaimed[msg.sender] = true;
            claimers.push(msg.sender);
        }

        emit Transfer(address(this), msg.sender, claimAmount);
        emit TokensClaimed(msg.sender, claimAmount, block.timestamp);
    }

    /**
     * @dev Check if user can claim tokens
     * @param user User address
     * @return true if user can claim
     */
    function canUserClaim(address user) public view returns (bool) {
        if (balances[address(this)] < claimAmount) {
            return false;
        }
        return lastClaimTime[user] == 0 || 
               block.timestamp >= lastClaimTime[user] + CLAIM_INTERVAL;
    }

    /**
     * @dev Get time until next claim
     * @param user User address
     * @return Seconds until next claim (0 if can claim now)
     */
    function getTimeUntilNextClaim(address user) public view returns (uint256) {
        if (lastClaimTime[user] == 0) {
            return 0;
        }

        uint256 nextClaimTime = lastClaimTime[user] + CLAIM_INTERVAL;
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }

        return nextClaimTime - block.timestamp;
    }

    /**
     * @dev Get user's last claim time
     * @param user User address
     * @return Last claim timestamp
     */
    function getLastClaimTime(address user) public view returns (uint256) {
        return lastClaimTime[user];
    }

    /**
     * @dev Get user's total claim count
     * @param user User address
     * @return Number of times user has claimed
     */
    function getUserClaimCount(address user) public view returns (uint256) {
        return claimCount[user];
    }

    /**
     * @dev Get user's total claimed amount
     * @param user User address
     * @return Total amount claimed by user
     */
    function getUserTotalClaimed(address user) public view returns (uint256) {
        return claimCount[user] * claimAmount;
    }

    /**
     * @dev Get all claimers
     * @return Array of claimer addresses
     */
    function getAllClaimers() public view returns (address[] memory) {
        return claimers;
    }

    /**
     * @dev Get faucet statistics
     * @return totalClaimsCount Total number of claims
     * @return totalClaimedAmt Total amount claimed
     * @return uniqueClaimers Number of unique claimers
     * @return faucetBalance Current faucet balance
     */
    function getFaucetStats() 
        public 
        view 
        returns (
            uint256 totalClaimsCount,
            uint256 totalClaimedAmt,
            uint256 uniqueClaimers,
            uint256 faucetBalance
        ) 
    {
        return (
            totalClaims,
            totalClaimedAmount,
            claimers.length,
            balances[address(this)]
        );
    }

    /**
     * @dev Update claim amount
     * @param newClaimAmount New claim amount
     */
    function setClaimAmount(uint256 newClaimAmount) public onlyOwner {
        require(newClaimAmount > 0, "Claim amount must be greater than 0");

        uint256 oldAmount = claimAmount;
        claimAmount = newClaimAmount;

        emit ClaimAmountUpdated(oldAmount, newClaimAmount);
    }

    /**
     * @dev Refill faucet
     * @param amount Amount to add to faucet
     */
    function refillFaucet(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[address(this)] += amount;

        emit Transfer(msg.sender, address(this), amount);
        emit FaucetRefilled(msg.sender, amount);
    }

    /**
     * @dev Mint new tokens to faucet (only owner)
     * @param amount Amount to mint
     */
    function mintToFaucet(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");

        totalSupply += amount;
        balances[address(this)] += amount;

        emit Transfer(address(0), address(this), amount);
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
     * @dev Increase allowance
     * @param spender Spender address
     * @param addedValue Amount to increase
     * @return true if successful
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease allowance
     * @param spender Spender address
     * @param subtractedValue Amount to decrease
     * @return true if successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        require(allowances[msg.sender][spender] >= subtractedValue, "Decreased allowance below zero");

        allowances[msg.sender][spender] -= subtractedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Get faucet balance
     * @return Faucet's token balance
     */
    function getFaucetBalance() public view returns (uint256) {
        return balances[address(this)];
    }

    /**
     * @dev Check if faucet has enough tokens
     * @return true if faucet can serve at least one claim
     */
    function isFaucetActive() public view returns (bool) {
        return balances[address(this)] >= claimAmount;
    }

    /**
     * @dev Get number of claims the faucet can serve
     * @return Number of possible claims
     */
    function getRemainingClaims() public view returns (uint256) {
        return balances[address(this)] / claimAmount;
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
