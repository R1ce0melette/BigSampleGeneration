// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DigitalCertificate
 * @dev An NFT minting system where each token represents a digital certificate with metadata
 */
contract DigitalCertificate {
    struct Certificate {
        uint256 tokenId;
        address owner;
        string recipientName;
        string certificateType;
        string description;
        string metadataURI;
        uint256 issuedAt;
        address issuedBy;
        bool exists;
    }
    
    address public contractOwner;
    string public name = "Digital Certificate";
    string public symbol = "CERT";
    
    uint256 public tokenCount;
    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    
    mapping(address => bool) public isIssuer;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(uint256 indexed tokenId, address indexed recipient, string recipientName, address indexed issuer);
    event IssuerAdded(address indexed issuer);
    event IssuerRemoved(address indexed issuer);
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can perform this action");
        _;
    }
    
    modifier onlyIssuer() {
        require(isIssuer[msg.sender] || msg.sender == contractOwner, "Only issuer can perform this action");
        _;
    }
    
    constructor() {
        contractOwner = msg.sender;
        isIssuer[msg.sender] = true;
    }
    
    /**
     * @dev Mint a new certificate
     * @param recipient The address to receive the certificate
     * @param recipientName The name of the recipient
     * @param certificateType The type of certificate
     * @param description Description of the certificate
     * @param metadataURI URI to additional metadata
     */
    function mintCertificate(
        address recipient,
        string memory recipientName,
        string memory certificateType,
        string memory description,
        string memory metadataURI
    ) external onlyIssuer {
        require(recipient != address(0), "Invalid recipient address");
        require(bytes(recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(certificateType).length > 0, "Certificate type cannot be empty");
        
        tokenCount++;
        uint256 tokenId = tokenCount;
        
        certificates[tokenId] = Certificate({
            tokenId: tokenId,
            owner: recipient,
            recipientName: recipientName,
            certificateType: certificateType,
            description: description,
            metadataURI: metadataURI,
            issuedAt: block.timestamp,
            issuedBy: msg.sender,
            exists: true
        });
        
        tokenOwner[tokenId] = recipient;
        balanceOf[recipient]++;
        
        emit Transfer(address(0), recipient, tokenId);
        emit CertificateMinted(tokenId, recipient, recipientName, msg.sender);
    }
    
    /**
     * @dev Transfer a certificate to another address
     * @param to The recipient address
     * @param tokenId The token ID to transfer
     */
    function transfer(address to, uint256 tokenId) external {
        require(tokenOwner[tokenId] == msg.sender, "Not the token owner");
        require(to != address(0), "Invalid recipient address");
        require(certificates[tokenId].exists, "Certificate does not exist");
        
        address from = msg.sender;
        
        // Clear approval
        delete tokenApprovals[tokenId];
        
        // Update balances
        balanceOf[from]--;
        balanceOf[to]++;
        
        // Update ownership
        tokenOwner[tokenId] = to;
        certificates[tokenId].owner = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @dev Transfer from an approved address
     * @param from The current owner
     * @param to The recipient address
     * @param tokenId The token ID to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(certificates[tokenId].exists, "Certificate does not exist");
        require(tokenOwner[tokenId] == from, "From address is not the owner");
        require(to != address(0), "Invalid recipient address");
        require(
            msg.sender == from ||
            tokenApprovals[tokenId] == msg.sender ||
            operatorApprovals[from][msg.sender],
            "Not authorized to transfer"
        );
        
        // Clear approval
        delete tokenApprovals[tokenId];
        
        // Update balances
        balanceOf[from]--;
        balanceOf[to]++;
        
        // Update ownership
        tokenOwner[tokenId] = to;
        certificates[tokenId].owner = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @dev Approve an address to transfer a specific token
     * @param approved The address to approve
     * @param tokenId The token ID
     */
    function approve(address approved, uint256 tokenId) external {
        require(tokenOwner[tokenId] == msg.sender, "Not the token owner");
        require(certificates[tokenId].exists, "Certificate does not exist");
        
        tokenApprovals[tokenId] = approved;
        
        emit Approval(msg.sender, approved, tokenId);
    }
    
    /**
     * @dev Set approval for all tokens
     * @param operator The operator address
     * @param approved Whether to approve or revoke
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Cannot approve yourself");
        
        operatorApprovals[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /**
     * @dev Get the approved address for a token
     * @param tokenId The token ID
     * @return The approved address
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        require(certificates[tokenId].exists, "Certificate does not exist");
        return tokenApprovals[tokenId];
    }
    
    /**
     * @dev Check if an operator is approved for all tokens of an owner
     * @param owner The owner address
     * @param operator The operator address
     * @return True if approved, false otherwise
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return operatorApprovals[owner][operator];
    }
    
    /**
     * @dev Get certificate details
     * @param tokenId The token ID
     * @return tokenIdOut Token ID
     * @return owner Owner address
     * @return recipientName Recipient name
     * @return certificateType Certificate type
     * @return description Description
     * @return metadataURI Metadata URI
     * @return issuedAt Issued timestamp
     * @return issuedBy Issuer address
     */
    function getCertificate(uint256 tokenId) external view returns (
        uint256 tokenIdOut,
        address owner,
        string memory recipientName,
        string memory certificateType,
        string memory description,
        string memory metadataURI,
        uint256 issuedAt,
        address issuedBy
    ) {
        require(certificates[tokenId].exists, "Certificate does not exist");
        Certificate memory cert = certificates[tokenId];
        
        return (
            cert.tokenId,
            cert.owner,
            cert.recipientName,
            cert.certificateType,
            cert.description,
            cert.metadataURI,
            cert.issuedAt,
            cert.issuedBy
        );
    }
    
    /**
     * @dev Get all tokens owned by an address
     * @param owner The owner address
     * @return Array of token IDs
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf[owner];
        uint256[] memory tokens = new uint256[](balance);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (tokenOwner[i] == owner) {
                tokens[index] = i;
                index++;
            }
        }
        
        return tokens;
    }
    
    /**
     * @dev Get certificates by type
     * @param certificateType The certificate type to filter by
     * @return Array of token IDs
     */
    function getCertificatesByType(string memory certificateType) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count certificates of this type
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (certificates[i].exists && 
                keccak256(bytes(certificates[i].certificateType)) == keccak256(bytes(certificateType))) {
                count++;
            }
        }
        
        // Collect token IDs
        uint256[] memory tokens = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (certificates[i].exists && 
                keccak256(bytes(certificates[i].certificateType)) == keccak256(bytes(certificateType))) {
                tokens[index] = i;
                index++;
            }
        }
        
        return tokens;
    }
    
    /**
     * @dev Get certificates issued by a specific issuer
     * @param issuer The issuer address
     * @return Array of token IDs
     */
    function getCertificatesByIssuer(address issuer) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count certificates by this issuer
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (certificates[i].exists && certificates[i].issuedBy == issuer) {
                count++;
            }
        }
        
        // Collect token IDs
        uint256[] memory tokens = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (certificates[i].exists && certificates[i].issuedBy == issuer) {
                tokens[index] = i;
                index++;
            }
        }
        
        return tokens;
    }
    
    /**
     * @dev Get the owner of a token
     * @param tokenId The token ID
     * @return The owner address
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        require(certificates[tokenId].exists, "Certificate does not exist");
        return tokenOwner[tokenId];
    }
    
    /**
     * @dev Check if a token exists
     * @param tokenId The token ID
     * @return True if exists, false otherwise
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return certificates[tokenId].exists;
    }
    
    /**
     * @dev Add an issuer (contract owner only)
     * @param issuer The address to add as issuer
     */
    function addIssuer(address issuer) external onlyOwner {
        require(issuer != address(0), "Invalid issuer address");
        require(!isIssuer[issuer], "Already an issuer");
        
        isIssuer[issuer] = true;
        
        emit IssuerAdded(issuer);
    }
    
    /**
     * @dev Remove an issuer (contract owner only)
     * @param issuer The address to remove as issuer
     */
    function removeIssuer(address issuer) external onlyOwner {
        require(issuer != contractOwner, "Cannot remove contract owner as issuer");
        require(isIssuer[issuer], "Not an issuer");
        
        isIssuer[issuer] = false;
        
        emit IssuerRemoved(issuer);
    }
    
    /**
     * @dev Get total supply
     * @return The total number of minted certificates
     */
    function totalSupply() external view returns (uint256) {
        return tokenCount;
    }
    
    /**
     * @dev Transfer contract ownership
     * @param newOwner The new owner's address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        
        // Make new owner an issuer
        if (!isIssuer[newOwner]) {
            isIssuer[newOwner] = true;
        }
        
        contractOwner = newOwner;
    }
}
