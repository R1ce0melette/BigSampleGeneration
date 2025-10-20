// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenAirdrop {
    address public owner;
    string public tokenName;
    string public tokenSymbol;
    uint256 public totalSupply;
    uint256 public airdropAmount;

    mapping(address => uint256) public balances;
    mapping(address => bool) public hasClaimedAirdrop;
    mapping(address => bool) public isEligible;

    address[] public eligibleAddresses;

    event AirdropConfigured(uint256 airdropAmount, uint256 eligibleCount);
    event AddressAddedToWhitelist(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AirdropClaimed(address indexed recipient, uint256 amount);
    event TokensDistributed(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply,
        uint256 _airdropAmount
    ) {
        owner = msg.sender;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        totalSupply = _totalSupply;
        airdropAmount = _airdropAmount;
        balances[owner] = _totalSupply;
    }

    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(!isEligible[account], "Address already whitelisted");

        isEligible[account] = true;
        eligibleAddresses.push(account);

        emit AddressAddedToWhitelist(account);
    }

    function addMultipleToWhitelist(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Invalid address");
            if (!isEligible[accounts[i]]) {
                isEligible[accounts[i]] = true;
                eligibleAddresses.push(accounts[i]);
                emit AddressAddedToWhitelist(accounts[i]);
            }
        }
    }

    function removeFromWhitelist(address account) external onlyOwner {
        require(isEligible[account], "Address not whitelisted");
        
        isEligible[account] = false;

        // Remove from eligibleAddresses array
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (eligibleAddresses[i] == account) {
                eligibleAddresses[i] = eligibleAddresses[eligibleAddresses.length - 1];
                eligibleAddresses.pop();
                break;
            }
        }

        emit AddressRemovedFromWhitelist(account);
    }

    function claimAirdrop() external {
        require(isEligible[msg.sender], "Not eligible for airdrop");
        require(!hasClaimedAirdrop[msg.sender], "Airdrop already claimed");
        require(balances[owner] >= airdropAmount, "Insufficient tokens for airdrop");

        hasClaimedAirdrop[msg.sender] = true;
        balances[owner] -= airdropAmount;
        balances[msg.sender] += airdropAmount;

        emit AirdropClaimed(msg.sender, airdropAmount);
    }

    function distributeAirdrop(address[] memory recipients) external onlyOwner {
        uint256 totalAmount = recipients.length * airdropAmount;
        require(balances[owner] >= totalAmount, "Insufficient tokens for distribution");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(isEligible[recipients[i]], "Recipient not eligible");
            require(!hasClaimedAirdrop[recipients[i]], "Recipient already claimed");

            hasClaimedAirdrop[recipients[i]] = true;
            balances[owner] -= airdropAmount;
            balances[recipients[i]] += airdropAmount;

            emit TokensDistributed(recipients[i], airdropAmount);
        }
    }

    function distributeToAll() external onlyOwner {
        uint256 unclaimedCount = 0;
        
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (!hasClaimedAirdrop[eligibleAddresses[i]]) {
                unclaimedCount++;
            }
        }

        uint256 totalAmount = unclaimedCount * airdropAmount;
        require(balances[owner] >= totalAmount, "Insufficient tokens for distribution");

        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            address recipient = eligibleAddresses[i];
            if (!hasClaimedAirdrop[recipient]) {
                hasClaimedAirdrop[recipient] = true;
                balances[owner] -= airdropAmount;
                balances[recipient] += airdropAmount;

                emit TokensDistributed(recipient, airdropAmount);
            }
        }
    }

    function updateAirdropAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Airdrop amount must be greater than 0");
        airdropAmount = newAmount;
        emit AirdropConfigured(newAmount, eligibleAddresses.length);
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    function hasUserClaimed(address account) external view returns (bool) {
        return hasClaimedAirdrop[account];
    }

    function isUserEligible(address account) external view returns (bool) {
        return isEligible[account];
    }

    function getEligibleAddresses() external view returns (address[] memory) {
        return eligibleAddresses;
    }

    function getUnclaimedCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (!hasClaimedAirdrop[eligibleAddresses[i]]) {
                count++;
            }
        }
        return count;
    }

    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
