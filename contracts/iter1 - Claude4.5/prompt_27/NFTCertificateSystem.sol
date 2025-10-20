// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFTCertificateSystem
 * @dev An NFT minting system where each token represents a digital certificate with metadata
 */
contract NFTCertificateSystem {
    struct Certificate {
        uint256 tokenId;
        string name;
        string description;
        string certificateType;
        address recipient;
        uint256 issuedDate;
        address issuer;
        string metadataURI;
        bool revoked;
    }
    
    uint256 private tokenCounter;
    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(address => uint256[]) private ownerTokens;
    
    address public contractOwner;
    mapping(address => bool) public authorizedIssuers;
    
    string public constant name = "Digital Certificate NFT";
    string public constant symbol = "DCNFT";
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        address indexed issuer,
        string certificateType
    );
    event CertificateRevoked(uint256 indexed tokenId, address indexed revoker);
    event IssuerAuthorized(address indexed issuer);
    event IssuerRevoked(address indexed issuer);
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner");
        _;
    }
    
    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender] || msg.sender == contractOwner, "Not authorized issuer");
        _;
    }
    
    modifier tokenExists(uint256 tokenId) {
        require(tokenOwner[tokenId] != address(0), "Token does not exist");
        _;
    }
    
    constructor() {
        contractOwner = msg.sender;
        authorizedIssuers[msg.sender] = true;
    }
    
    /**
     * @dev Mint a new certificate NFT
     * @param recipient The address to receive the certificate
     * @param certificateName The name of the certificate
     * @param description Description of the certificate
     * @param certificateType Type of certificate (e.g., "Completion", "Achievement")
     * @param metadataURI URI pointing to additional metadata
     * @return tokenId The ID of the minted token
     */
    function mintCertificate(
        address recipient,
        string memory certificateName,
        string memory description,
        string memory certificateType,
        string memory metadataURI
    ) external onlyAuthorizedIssuer returns (uint256) {
        require(recipient != address(0), "Invalid recipient");
        require(bytes(certificateName).length > 0, "Name cannot be empty");
        require(bytes(certificateType).length > 0, "Certificate type cannot be empty");
        
        tokenCounter++;
        uint256 newTokenId = tokenCounter;
        
        certificates[newTokenId] = Certificate({
            tokenId: newTokenId,
            name: certificateName,
            description: description,
            certificateType: certificateType,
            recipient: recipient,
            issuedDate: block.timestamp,
            issuer: msg.sender,
            metadataURI: metadataURI,
            revoked: false
        });
        
        tokenOwner[newTokenId] = recipient;
        ownerTokenCount[recipient]++;
        ownerTokens[recipient].push(newTokenId);
        
        emit Transfer(address(0), recipient, newTokenId);
        emit CertificateMinted(newTokenId, recipient, msg.sender, certificateType);
        
        return newTokenId;
    }
    
    /**
     * @dev Revoke a certificate
     * @param tokenId The ID of the token to revoke
     */
    function revokeCertificate(uint256 tokenId) external tokenExists(tokenId) {
        Certificate storage cert = certificates[tokenId];
        require(
            msg.sender == cert.issuer || msg.sender == contractOwner,
            "Only issuer or contract owner can revoke"
        );
        require(!cert.revoked, "Certificate already revoked");
        
        cert.revoked = true;
        
        emit CertificateRevoked(tokenId, msg.sender);
    }
    
    /**
     * @dev Update metadata URI for a certificate
     * @param tokenId The ID of the token
     * @param newMetadataURI The new metadata URI
     */
    function updateMetadataURI(uint256 tokenId, string memory newMetadataURI) 
        external 
        tokenExists(tokenId) 
        onlyAuthorizedIssuer 
    {
        Certificate storage cert = certificates[tokenId];
        require(msg.sender == cert.issuer || msg.sender == contractOwner, "Only issuer can update");
        
        cert.metadataURI = newMetadataURI;
        
        emit MetadataUpdated(tokenId, newMetadataURI);
    }
    
    /**
     * @dev Authorize an address to issue certificates
     * @param issuer The address to authorize
     */
    function authorizeIssuer(address issuer) external onlyOwner {
        require(issuer != address(0), "Invalid issuer address");
        require(!authorizedIssuers[issuer], "Already authorized");
        
        authorizedIssuers[issuer] = true;
        
        emit IssuerAuthorized(issuer);
    }
    
    /**
     * @dev Revoke issuer authorization
     * @param issuer The address to revoke
     */
    function revokeIssuer(address issuer) external onlyOwner {
        require(issuer != contractOwner, "Cannot revoke contract owner");
        require(authorizedIssuers[issuer], "Not an authorized issuer");
        
        authorizedIssuers[issuer] = false;
        
        emit IssuerRevoked(issuer);
    }
    
    /**
     * @dev Get the owner of a token
     * @param tokenId The token ID
     * @return The owner's address
     */
    function ownerOf(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return tokenOwner[tokenId];
    }
    
    /**
     * @dev Get the balance of tokens owned by an address
     * @param owner The owner's address
     * @return The number of tokens owned
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Invalid owner address");
        return ownerTokenCount[owner];
    }
    
    /**
     * @dev Transfer a token to another address
     * @param to The recipient address
     * @param tokenId The token ID
     */
    function transfer(address to, uint256 tokenId) external tokenExists(tokenId) {
        require(tokenOwner[tokenId] == msg.sender, "Not token owner");
        require(to != address(0), "Invalid recipient");
        require(to != msg.sender, "Cannot transfer to yourself");
        
        _transfer(msg.sender, to, tokenId);
    }
    
    /**
     * @dev Transfer a token from one address to another
     * @param from The current owner
     * @param to The recipient address
     * @param tokenId The token ID
     */
    function transferFrom(address from, address to, uint256 tokenId) external tokenExists(tokenId) {
        require(tokenOwner[tokenId] == from, "From address is not owner");
        require(to != address(0), "Invalid recipient");
        require(
            msg.sender == from || 
            tokenApprovals[tokenId] == msg.sender || 
            operatorApprovals[from][msg.sender],
            "Not authorized to transfer"
        );
        
        _transfer(from, to, tokenId);
    }
    
    /**
     * @dev Approve an address to transfer a specific token
     * @param approved The address to approve
     * @param tokenId The token ID
     */
    function approve(address approved, uint256 tokenId) external tokenExists(tokenId) {
        address owner = tokenOwner[tokenId];
        require(msg.sender == owner, "Not token owner");
        require(approved != owner, "Cannot approve to owner");
        
        tokenApprovals[tokenId] = approved;
        
        emit Approval(owner, approved, tokenId);
    }
    
    /**
     * @dev Set approval for an operator to manage all tokens
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
    function getApproved(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return tokenApprovals[tokenId];
    }
    
    /**
     * @dev Check if an operator is approved for all tokens of an owner
     * @param owner The owner address
     * @param operator The operator address
     * @return Whether the operator is approved
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return operatorApprovals[owner][operator];
    }
    
    /**
     * @dev Get certificate details
     * @param tokenId The token ID
     * @return name Certificate name
     * @return description Certificate description
     * @return certificateType Type of certificate
     * @return recipient Original recipient
     * @return issuedDate Timestamp of issuance
     * @return issuer Address of the issuer
     * @return metadataURI URI for additional metadata
     * @return revoked Whether the certificate is revoked
     */
    function getCertificateDetails(uint256 tokenId) external view tokenExists(tokenId) returns (
        string memory,
        string memory,
        string memory,
        address,
        uint256,
        address,
        string memory,
        bool
    ) {
        Certificate memory cert = certificates[tokenId];
        return (
            cert.name,
            cert.description,
            cert.certificateType,
            cert.recipient,
            cert.issuedDate,
            cert.issuer,
            cert.metadataURI,
            cert.revoked
        );
    }
    
    /**
     * @dev Get all tokens owned by an address
     * @param owner The owner's address
     * @return Array of token IDs
     */
    function getTokensByOwner(address owner) external view returns (uint256[] memory) {
        return ownerTokens[owner];
    }
    
    /**
     * @dev Get tokens issued by a specific issuer
     * @param issuer The issuer's address
     * @return Array of token IDs
     */
    function getTokensByIssuer(address issuer) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count tokens issued by this issuer
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (certificates[i].issuer == issuer) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (certificates[i].issuer == issuer) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Get tokens of a specific certificate type
     * @param certificateType The type of certificate
     * @return Array of token IDs
     */
    function getTokensByCertificateType(string memory certificateType) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count tokens of this type
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (keccak256(bytes(certificates[i].certificateType)) == keccak256(bytes(certificateType))) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (keccak256(bytes(certificates[i].certificateType)) == keccak256(bytes(certificateType))) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Check if a certificate is valid (exists and not revoked)
     * @param tokenId The token ID
     * @return Whether the certificate is valid
     */
    function isCertificateValid(uint256 tokenId) external view returns (bool) {
        if (tokenOwner[tokenId] == address(0)) {
            return false;
        }
        return !certificates[tokenId].revoked;
    }
    
    /**
     * @dev Get the total number of minted certificates
     * @return The total count
     */
    function totalSupply() external view returns (uint256) {
        return tokenCounter;
    }
    
    /**
     * @dev Get token URI (metadata URI)
     * @param tokenId The token ID
     * @return The metadata URI
     */
    function tokenURI(uint256 tokenId) external view tokenExists(tokenId) returns (string memory) {
        return certificates[tokenId].metadataURI;
    }
    
    /**
     * @dev Internal function to transfer tokens
     * @param from The current owner
     * @param to The recipient
     * @param tokenId The token ID
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        // Clear approval
        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }
        
        // Update ownership
        tokenOwner[tokenId] = to;
        ownerTokenCount[from]--;
        ownerTokenCount[to]++;
        
        // Update owner tokens array for 'from'
        uint256[] storage fromTokens = ownerTokens[from];
        for (uint256 i = 0; i < fromTokens.length; i++) {
            if (fromTokens[i] == tokenId) {
                fromTokens[i] = fromTokens[fromTokens.length - 1];
                fromTokens.pop();
                break;
            }
        }
        
        // Add to 'to' tokens array
        ownerTokens[to].push(tokenId);
        
        emit Transfer(from, to, tokenId);
    }
}
