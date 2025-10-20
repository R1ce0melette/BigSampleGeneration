// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFTCertificate
 * @dev NFT minting system where each token represents a digital certificate with metadata
 */
contract NFTCertificate {
    // Token metadata structure
    struct Certificate {
        uint256 tokenId;
        string title;
        string description;
        string recipientName;
        uint256 issuedDate;
        address issuer;
        bool exists;
    }

    // State variables
    address public owner;
    uint256 private tokenIdCounter;
    string public contractName;
    string public contractSymbol;

    // Mappings
    mapping(uint256 => address) private tokenOwners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;
    mapping(uint256 => Certificate) private certificates;
    mapping(address => uint256[]) private ownedTokens;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(uint256 indexed tokenId, address indexed recipient, string title, address indexed issuer);
    event CertificateUpdated(uint256 indexed tokenId, string title, string description);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(certificates[tokenId].exists, "Token does not exist");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(tokenOwners[tokenId] == msg.sender, "Not token owner");
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(
            tokenOwners[tokenId] == msg.sender ||
            tokenApprovals[tokenId] == msg.sender ||
            operatorApprovals[tokenOwners[tokenId]][msg.sender],
            "Not authorized"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        contractName = _name;
        contractSymbol = _symbol;
        tokenIdCounter = 1;
    }

    /**
     * @dev Mint a new certificate NFT
     * @param recipient Address to receive the certificate
     * @param title Certificate title
     * @param description Certificate description
     * @param recipientName Name of the certificate recipient
     */
    function mintCertificate(
        address recipient,
        string memory title,
        string memory description,
        string memory recipientName
    ) public returns (uint256) {
        require(recipient != address(0), "Invalid recipient address");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(recipientName).length > 0, "Recipient name cannot be empty");

        uint256 newTokenId = tokenIdCounter;
        tokenIdCounter++;

        certificates[newTokenId] = Certificate({
            tokenId: newTokenId,
            title: title,
            description: description,
            recipientName: recipientName,
            issuedDate: block.timestamp,
            issuer: msg.sender,
            exists: true
        });

        tokenOwners[newTokenId] = recipient;
        balances[recipient]++;
        ownedTokens[recipient].push(newTokenId);

        emit Transfer(address(0), recipient, newTokenId);
        emit CertificateMinted(newTokenId, recipient, title, msg.sender);

        return newTokenId;
    }

    /**
     * @dev Update certificate metadata (only by issuer)
     * @param tokenId Token ID to update
     * @param title New title
     * @param description New description
     */
    function updateCertificate(
        uint256 tokenId,
        string memory title,
        string memory description
    ) public tokenExists(tokenId) {
        require(certificates[tokenId].issuer == msg.sender, "Only issuer can update");
        require(bytes(title).length > 0, "Title cannot be empty");

        certificates[tokenId].title = title;
        certificates[tokenId].description = description;

        emit CertificateUpdated(tokenId, title, description);
    }

    /**
     * @dev Transfer token to another address
     * @param to Recipient address
     * @param tokenId Token ID to transfer
     */
    function transfer(address to, uint256 tokenId) public tokenExists(tokenId) onlyTokenOwner(tokenId) {
        require(to != address(0), "Invalid recipient address");
        require(to != msg.sender, "Cannot transfer to yourself");

        _transfer(msg.sender, to, tokenId);
    }

    /**
     * @dev Transfer from one address to another (requires approval)
     * @param from Current owner address
     * @param to Recipient address
     * @param tokenId Token ID to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public tokenExists(tokenId) onlyTokenOwnerOrApproved(tokenId) {
        require(tokenOwners[tokenId] == from, "From address is not token owner");
        require(to != address(0), "Invalid recipient address");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Approve another address to transfer a specific token
     * @param approved Address to approve
     * @param tokenId Token ID to approve
     */
    function approve(address approved, uint256 tokenId) public tokenExists(tokenId) onlyTokenOwner(tokenId) {
        require(approved != msg.sender, "Cannot approve yourself");

        tokenApprovals[tokenId] = approved;
        emit Approval(msg.sender, approved, tokenId);
    }

    /**
     * @dev Set approval for all tokens
     * @param operator Address to set approval for
     * @param approved Approval status
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Cannot set approval for yourself");

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Burn a certificate token
     * @param tokenId Token ID to burn
     */
    function burn(uint256 tokenId) public tokenExists(tokenId) onlyTokenOwner(tokenId) {
        address tokenOwner = tokenOwners[tokenId];

        delete tokenApprovals[tokenId];
        delete certificates[tokenId];
        delete tokenOwners[tokenId];
        balances[tokenOwner]--;

        // Remove from owned tokens array
        _removeFromOwnedTokens(tokenOwner, tokenId);

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    /**
     * @dev Transfer contract ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");

        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Internal transfer function
     * @param from Current owner
     * @param to New owner
     * @param tokenId Token ID
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        delete tokenApprovals[tokenId];
        
        balances[from]--;
        balances[to]++;
        tokenOwners[tokenId] = to;

        _removeFromOwnedTokens(from, tokenId);
        ownedTokens[to].push(tokenId);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Remove token from owned tokens array
     * @param tokenOwner Owner address
     * @param tokenId Token ID to remove
     */
    function _removeFromOwnedTokens(address tokenOwner, uint256 tokenId) private {
        uint256[] storage tokens = ownedTokens[tokenOwner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    // View Functions

    /**
     * @dev Get owner of a specific token
     * @param tokenId Token ID
     * @return Token owner address
     */
    function ownerOf(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return tokenOwners[tokenId];
    }

    /**
     * @dev Get balance of an address
     * @param account Address to check
     * @return Number of tokens owned
     */
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "Invalid address");
        return balances[account];
    }

    /**
     * @dev Get approved address for a token
     * @param tokenId Token ID
     * @return Approved address
     */
    function getApproved(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return tokenApprovals[tokenId];
    }

    /**
     * @dev Check if operator is approved for all tokens of an owner
     * @param tokenOwner Owner address
     * @param operator Operator address
     * @return Approval status
     */
    function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
        return operatorApprovals[tokenOwner][operator];
    }

    /**
     * @dev Get certificate details
     * @param tokenId Token ID
     * @return Certificate details
     */
    function getCertificate(uint256 tokenId) public view tokenExists(tokenId) returns (Certificate memory) {
        return certificates[tokenId];
    }

    /**
     * @dev Get certificate metadata
     * @param tokenId Token ID
     * @return title Certificate title
     * @return description Certificate description
     * @return recipientName Recipient name
     * @return issuedDate Issued timestamp
     * @return issuer Issuer address
     */
    function getCertificateMetadata(uint256 tokenId) 
        public 
        view 
        tokenExists(tokenId) 
        returns (
            string memory title,
            string memory description,
            string memory recipientName,
            uint256 issuedDate,
            address issuer
        ) 
    {
        Certificate memory cert = certificates[tokenId];
        return (cert.title, cert.description, cert.recipientName, cert.issuedDate, cert.issuer);
    }

    /**
     * @dev Get all tokens owned by an address
     * @param tokenOwner Owner address
     * @return Array of token IDs
     */
    function getTokensOwnedBy(address tokenOwner) public view returns (uint256[] memory) {
        return ownedTokens[tokenOwner];
    }

    /**
     * @dev Get all certificates issued by an address
     * @param issuer Issuer address
     * @return Array of token IDs
     */
    function getCertificatesIssuedBy(address issuer) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < tokenIdCounter; i++) {
            if (certificates[i].exists && certificates[i].issuer == issuer) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < tokenIdCounter; i++) {
            if (certificates[i].exists && certificates[i].issuer == issuer) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total supply of minted tokens
     * @return Total number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return tokenIdCounter - 1;
    }

    /**
     * @dev Get next token ID to be minted
     * @return Next token ID
     */
    function getNextTokenId() public view returns (uint256) {
        return tokenIdCounter;
    }

    /**
     * @dev Check if a token exists
     * @param tokenId Token ID to check
     * @return Existence status
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return certificates[tokenId].exists;
    }

    /**
     * @dev Get contract name
     * @return Contract name
     */
    function name() public view returns (string memory) {
        return contractName;
    }

    /**
     * @dev Get contract symbol
     * @return Contract symbol
     */
    function symbol() public view returns (string memory) {
        return contractSymbol;
    }

    /**
     * @dev Get token URI (simple implementation)
     * @param tokenId Token ID
     * @return Token URI placeholder
     */
    function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked("ipfs://certificate/", _toString(tokenId)));
    }

    /**
     * @dev Convert uint256 to string
     * @param value Value to convert
     * @return String representation
     */
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
