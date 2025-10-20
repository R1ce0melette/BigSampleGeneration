// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFTCertificate
 * @dev NFT minting system where each token represents a digital certificate with metadata
 */
contract NFTCertificate {
    // Certificate structure
    struct Certificate {
        uint256 tokenId;
        address owner;
        string name;
        string description;
        string issuer;
        string recipientName;
        uint256 issueDate;
        uint256 expiryDate;
        string certificateType;
        string metadataURI;
        bool revoked;
        uint256 createdAt;
    }

    // Token approval structure
    struct TokenApproval {
        address approved;
        uint256 tokenId;
    }

    // Issuer statistics
    struct IssuerStats {
        uint256 certificatesIssued;
        uint256 certificatesRevoked;
        uint256 activeCertificates;
    }

    // State variables
    address public owner;
    string public name;
    string public symbol;
    uint256 private tokenIdCounter;

    mapping(uint256 => Certificate) private certificates;
    mapping(uint256 => address) private tokenOwners;
    mapping(address => uint256) private ownerTokenCount;
    mapping(address => uint256[]) private ownerTokens;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;
    mapping(address => bool) public authorizedIssuers;
    mapping(address => IssuerStats) private issuerStats;

    uint256[] private allTokenIds;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(uint256 indexed tokenId, address indexed recipient, string certificateType, string recipientName);
    event CertificateRevoked(uint256 indexed tokenId, address indexed issuer);
    event IssuerAuthorized(address indexed issuer, address indexed authorizedBy);
    event IssuerRevoked(address indexed issuer, address indexed revokedBy);
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Not an authorized issuer");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(tokenOwners[tokenId] != address(0), "Token does not exist");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(tokenOwners[tokenId] == msg.sender, "Not the token owner");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenIdCounter = 0;
        authorizedIssuers[msg.sender] = true;
    }

    /**
     * @dev Mint a new certificate NFT
     * @param recipient Recipient address
     * @param certificateName Certificate name
     * @param description Certificate description
     * @param recipientName Name of the recipient
     * @param certificateType Type of certificate
     * @param metadataURI URI for metadata
     * @param expiryDate Expiry timestamp (0 for no expiry)
     * @return tokenId ID of the minted token
     */
    function mintCertificate(
        address recipient,
        string memory certificateName,
        string memory description,
        string memory recipientName,
        string memory certificateType,
        string memory metadataURI,
        uint256 expiryDate
    ) public onlyAuthorizedIssuer returns (uint256) {
        require(recipient != address(0), "Invalid recipient address");
        require(bytes(certificateName).length > 0, "Certificate name cannot be empty");
        require(bytes(recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(certificateType).length > 0, "Certificate type cannot be empty");
        
        if (expiryDate > 0) {
            require(expiryDate > block.timestamp, "Expiry date must be in the future");
        }

        tokenIdCounter++;
        uint256 newTokenId = tokenIdCounter;

        Certificate storage newCertificate = certificates[newTokenId];
        newCertificate.tokenId = newTokenId;
        newCertificate.owner = recipient;
        newCertificate.name = certificateName;
        newCertificate.description = description;
        newCertificate.issuer = _getIssuerName(msg.sender);
        newCertificate.recipientName = recipientName;
        newCertificate.issueDate = block.timestamp;
        newCertificate.expiryDate = expiryDate;
        newCertificate.certificateType = certificateType;
        newCertificate.metadataURI = metadataURI;
        newCertificate.revoked = false;
        newCertificate.createdAt = block.timestamp;

        tokenOwners[newTokenId] = recipient;
        ownerTokenCount[recipient]++;
        ownerTokens[recipient].push(newTokenId);
        allTokenIds.push(newTokenId);

        // Update issuer statistics
        issuerStats[msg.sender].certificatesIssued++;
        issuerStats[msg.sender].activeCertificates++;

        emit Transfer(address(0), recipient, newTokenId);
        emit CertificateMinted(newTokenId, recipient, certificateType, recipientName);

        return newTokenId;
    }

    /**
     * @dev Batch mint certificates
     * @param recipients Array of recipient addresses
     * @param certificateNames Array of certificate names
     * @param descriptions Array of descriptions
     * @param recipientNames Array of recipient names
     * @param certificateType Common certificate type for all
     * @param metadataURIs Array of metadata URIs
     * @param expiryDate Common expiry date for all
     * @return Array of minted token IDs
     */
    function batchMintCertificates(
        address[] memory recipients,
        string[] memory certificateNames,
        string[] memory descriptions,
        string[] memory recipientNames,
        string memory certificateType,
        string[] memory metadataURIs,
        uint256 expiryDate
    ) public onlyAuthorizedIssuer returns (uint256[] memory) {
        require(recipients.length > 0, "Empty recipients array");
        require(
            recipients.length == certificateNames.length &&
            recipients.length == descriptions.length &&
            recipients.length == recipientNames.length &&
            recipients.length == metadataURIs.length,
            "Array length mismatch"
        );

        uint256[] memory tokenIds = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenIds[i] = mintCertificate(
                recipients[i],
                certificateNames[i],
                descriptions[i],
                recipientNames[i],
                certificateType,
                metadataURIs[i],
                expiryDate
            );
        }

        return tokenIds;
    }

    /**
     * @dev Get issuer name as string
     * @param issuer Issuer address
     * @return Issuer address as string
     */
    function _getIssuerName(address issuer) private pure returns (string memory) {
        return _addressToString(issuer);
    }

    /**
     * @dev Convert address to string
     * @param addr Address to convert
     * @return String representation
     */
    function _addressToString(address addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Revoke a certificate
     * @param tokenId Token ID to revoke
     */
    function revokeCertificate(uint256 tokenId) 
        public 
        onlyAuthorizedIssuer 
        tokenExists(tokenId) 
    {
        require(!certificates[tokenId].revoked, "Certificate already revoked");

        certificates[tokenId].revoked = true;

        // Update issuer statistics
        issuerStats[msg.sender].certificatesRevoked++;
        issuerStats[msg.sender].activeCertificates--;

        emit CertificateRevoked(tokenId, msg.sender);
    }

    /**
     * @dev Update metadata URI
     * @param tokenId Token ID
     * @param newMetadataURI New metadata URI
     */
    function updateMetadata(uint256 tokenId, string memory newMetadataURI) 
        public 
        onlyAuthorizedIssuer 
        tokenExists(tokenId) 
    {
        require(!certificates[tokenId].revoked, "Cannot update revoked certificate");
        
        certificates[tokenId].metadataURI = newMetadataURI;

        emit MetadataUpdated(tokenId, newMetadataURI);
    }

    /**
     * @dev Transfer token to another address
     * @param from Current owner address
     * @param to Recipient address
     * @param tokenId Token ID to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        tokenExists(tokenId) 
    {
        require(to != address(0), "Invalid recipient address");
        require(tokenOwners[tokenId] == from, "From address is not the owner");
        require(
            msg.sender == from || 
            msg.sender == tokenApprovals[tokenId] || 
            operatorApprovals[from][msg.sender],
            "Not authorized to transfer"
        );
        require(!certificates[tokenId].revoked, "Cannot transfer revoked certificate");

        // Clear approval
        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }

        // Update ownership
        tokenOwners[tokenId] = to;
        certificates[tokenId].owner = to;
        ownerTokenCount[from]--;
        ownerTokenCount[to]++;

        // Update owner tokens arrays
        _removeTokenFromOwnerList(from, tokenId);
        ownerTokens[to].push(tokenId);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safe transfer token
     * @param from Current owner address
     * @param to Recipient address
     * @param tokenId Token ID to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
    }

    /**
     * @dev Remove token from owner's list
     * @param owner Owner address
     * @param tokenId Token ID to remove
     */
    function _removeTokenFromOwnerList(address owner, uint256 tokenId) private {
        uint256[] storage tokens = ownerTokens[owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    /**
     * @dev Approve address to transfer token
     * @param approved Address to approve
     * @param tokenId Token ID
     */
    function approve(address approved, uint256 tokenId) 
        public 
        tokenExists(tokenId)
        onlyTokenOwner(tokenId)
    {
        require(approved != msg.sender, "Cannot approve yourself");

        tokenApprovals[tokenId] = approved;

        emit Approval(msg.sender, approved, tokenId);
    }

    /**
     * @dev Set approval for all tokens
     * @param operator Operator address
     * @param approved Approval status
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Cannot set approval for yourself");

        operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Authorize an issuer
     * @param issuer Issuer address to authorize
     */
    function authorizeIssuer(address issuer) public onlyOwner {
        require(issuer != address(0), "Invalid issuer address");
        require(!authorizedIssuers[issuer], "Issuer already authorized");

        authorizedIssuers[issuer] = true;

        emit IssuerAuthorized(issuer, msg.sender);
    }

    /**
     * @dev Revoke issuer authorization
     * @param issuer Issuer address to revoke
     */
    function revokeIssuerAuthorization(address issuer) public onlyOwner {
        require(issuer != owner, "Cannot revoke owner authorization");
        require(authorizedIssuers[issuer], "Issuer not authorized");

        authorizedIssuers[issuer] = false;

        emit IssuerRevoked(issuer, msg.sender);
    }

    /**
     * @dev Get certificate details
     * @param tokenId Token ID
     * @return Certificate details
     */
    function getCertificate(uint256 tokenId) 
        public 
        view 
        tokenExists(tokenId)
        returns (Certificate memory) 
    {
        return certificates[tokenId];
    }

    /**
     * @dev Get token owner
     * @param tokenId Token ID
     * @return Owner address
     */
    function ownerOf(uint256 tokenId) 
        public 
        view 
        tokenExists(tokenId)
        returns (address) 
    {
        return tokenOwners[tokenId];
    }

    /**
     * @dev Get balance of owner
     * @param tokenOwner Owner address
     * @return Number of tokens owned
     */
    function balanceOf(address tokenOwner) public view returns (uint256) {
        require(tokenOwner != address(0), "Invalid owner address");
        return ownerTokenCount[tokenOwner];
    }

    /**
     * @dev Get tokens owned by address
     * @param tokenOwner Owner address
     * @return Array of token IDs
     */
    function tokensOfOwner(address tokenOwner) public view returns (uint256[] memory) {
        return ownerTokens[tokenOwner];
    }

    /**
     * @dev Get approved address for token
     * @param tokenId Token ID
     * @return Approved address
     */
    function getApproved(uint256 tokenId) 
        public 
        view 
        tokenExists(tokenId)
        returns (address) 
    {
        return tokenApprovals[tokenId];
    }

    /**
     * @dev Check if operator is approved for all
     * @param tokenOwner Owner address
     * @param operator Operator address
     * @return true if approved
     */
    function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
        return operatorApprovals[tokenOwner][operator];
    }

    /**
     * @dev Get token URI
     * @param tokenId Token ID
     * @return Metadata URI
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        tokenExists(tokenId)
        returns (string memory) 
    {
        return certificates[tokenId].metadataURI;
    }

    /**
     * @dev Check if certificate is valid
     * @param tokenId Token ID
     * @return true if valid
     */
    function isCertificateValid(uint256 tokenId) 
        public 
        view 
        tokenExists(tokenId)
        returns (bool) 
    {
        Certificate memory cert = certificates[tokenId];
        
        if (cert.revoked) {
            return false;
        }
        
        if (cert.expiryDate > 0 && block.timestamp > cert.expiryDate) {
            return false;
        }
        
        return true;
    }

    /**
     * @dev Get all certificates
     * @return Array of all certificates
     */
    function getAllCertificates() public view returns (Certificate[] memory) {
        Certificate[] memory allCertificates = new Certificate[](allTokenIds.length);
        
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            allCertificates[i] = certificates[allTokenIds[i]];
        }
        
        return allCertificates;
    }

    /**
     * @dev Get valid certificates
     * @return Array of valid certificates
     */
    function getValidCertificates() public view returns (Certificate[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            if (isCertificateValid(allTokenIds[i])) {
                count++;
            }
        }

        Certificate[] memory result = new Certificate[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            if (isCertificateValid(tokenId)) {
                result[index] = certificates[tokenId];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get certificates by type
     * @param certificateType Certificate type to filter
     * @return Array of certificates of specified type
     */
    function getCertificatesByType(string memory certificateType) 
        public 
        view 
        returns (Certificate[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            if (_compareStrings(certificates[allTokenIds[i]].certificateType, certificateType)) {
                count++;
            }
        }

        Certificate[] memory result = new Certificate[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            if (_compareStrings(certificates[tokenId].certificateType, certificateType)) {
                result[index] = certificates[tokenId];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Compare two strings
     * @param a First string
     * @param b Second string
     * @return true if equal
     */
    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @dev Get revoked certificates
     * @return Array of revoked certificates
     */
    function getRevokedCertificates() public view returns (Certificate[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            if (certificates[allTokenIds[i]].revoked) {
                count++;
            }
        }

        Certificate[] memory result = new Certificate[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            if (certificates[tokenId].revoked) {
                result[index] = certificates[tokenId];
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get expired certificates
     * @return Array of expired certificates
     */
    function getExpiredCertificates() public view returns (Certificate[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            Certificate memory cert = certificates[allTokenIds[i]];
            if (cert.expiryDate > 0 && block.timestamp > cert.expiryDate && !cert.revoked) {
                count++;
            }
        }

        Certificate[] memory result = new Certificate[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            Certificate memory cert = certificates[tokenId];
            if (cert.expiryDate > 0 && block.timestamp > cert.expiryDate && !cert.revoked) {
                result[index] = cert;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get issuer statistics
     * @param issuer Issuer address
     * @return IssuerStats details
     */
    function getIssuerStats(address issuer) public view returns (IssuerStats memory) {
        return issuerStats[issuer];
    }

    /**
     * @dev Get total supply of tokens
     * @return Total number of tokens
     */
    function totalSupply() public view returns (uint256) {
        return tokenIdCounter;
    }

    /**
     * @dev Get total active certificates
     * @return Number of active (valid and not revoked) certificates
     */
    function getTotalActiveCertificates() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            if (isCertificateValid(allTokenIds[i])) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        
        // Transfer authorized issuer status
        authorizedIssuers[newOwner] = true;
        
        owner = newOwner;
    }

    /**
     * @dev Check if address supports interface
     * @param interfaceId Interface identifier
     * @return true if supported
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x01ffc9a7;   // ERC165
    }
}
