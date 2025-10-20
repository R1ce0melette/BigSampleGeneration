// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFTCertificate
 * @dev An NFT minting system where each token represents a digital certificate with metadata
 */
contract NFTCertificate {
    struct Certificate {
        uint256 tokenId;
        address owner;
        string name;
        string description;
        string metadataURI;
        uint256 mintedAt;
        address mintedBy;
    }
    
    string public contractName;
    string public contractSymbol;
    
    uint256 public totalSupply;
    address public owner;
    
    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public ownerTokens;
    mapping(uint256 => bool) public tokenExists;
    
    // Events
    event CertificateMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 timestamp);
    event CertificateTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event CertificateBurned(uint256 indexed tokenId, address indexed owner);
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenExists[_tokenId], "Token does not exist");
        require(certificates[_tokenId].owner == msg.sender, "Only token owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the NFT contract
     * @param _name The name of the NFT collection
     * @param _symbol The symbol of the NFT collection
     */
    constructor(string memory _name, string memory _symbol) {
        contractName = _name;
        contractSymbol = _symbol;
        owner = msg.sender;
    }
    
    /**
     * @dev Mints a new NFT certificate
     * @param _to The address to mint the certificate to
     * @param _name The name of the certificate
     * @param _description The description of the certificate
     * @param _metadataURI The URI for the certificate metadata
     */
    function mintCertificate(
        address _to,
        string memory _name,
        string memory _description,
        string memory _metadataURI
    ) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        totalSupply++;
        uint256 tokenId = totalSupply;
        
        certificates[tokenId] = Certificate({
            tokenId: tokenId,
            owner: _to,
            name: _name,
            description: _description,
            metadataURI: _metadataURI,
            mintedAt: block.timestamp,
            mintedBy: msg.sender
        });
        
        tokenExists[tokenId] = true;
        ownerTokens[_to].push(tokenId);
        
        emit CertificateMinted(tokenId, _to, _name, block.timestamp);
    }
    
    /**
     * @dev Transfers a certificate to another address
     * @param _to The address to transfer to
     * @param _tokenId The ID of the token to transfer
     */
    function transferCertificate(address _to, uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address");
        require(_to != msg.sender, "Cannot transfer to self");
        
        address from = certificates[_tokenId].owner;
        certificates[_tokenId].owner = _to;
        ownerTokens[_to].push(_tokenId);
        
        emit CertificateTransferred(_tokenId, from, _to);
    }
    
    /**
     * @dev Burns (destroys) a certificate
     * @param _tokenId The ID of the token to burn
     */
    function burnCertificate(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        address tokenOwner = certificates[_tokenId].owner;
        
        delete certificates[_tokenId];
        tokenExists[_tokenId] = false;
        
        emit CertificateBurned(_tokenId, tokenOwner);
    }
    
    /**
     * @dev Updates the metadata URI for a certificate (only owner)
     * @param _tokenId The ID of the token
     * @param _newMetadataURI The new metadata URI
     */
    function updateMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyOwner {
        require(tokenExists[_tokenId], "Token does not exist");
        
        certificates[_tokenId].metadataURI = _newMetadataURI;
        
        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }
    
    /**
     * @dev Returns the details of a certificate
     * @param _tokenId The ID of the token
     * @return tokenId The token ID
     * @return tokenOwner The owner's address
     * @return name The certificate name
     * @return description The certificate description
     * @return metadataURI The metadata URI
     * @return mintedAt When the certificate was minted
     * @return mintedBy Who minted the certificate
     */
    function getCertificate(uint256 _tokenId) external view returns (
        uint256 tokenId,
        address tokenOwner,
        string memory name,
        string memory description,
        string memory metadataURI,
        uint256 mintedAt,
        address mintedBy
    ) {
        require(tokenExists[_tokenId], "Token does not exist");
        
        Certificate memory cert = certificates[_tokenId];
        
        return (
            cert.tokenId,
            cert.owner,
            cert.name,
            cert.description,
            cert.metadataURI,
            cert.mintedAt,
            cert.mintedBy
        );
    }
    
    /**
     * @dev Returns the owner of a specific token
     * @param _tokenId The ID of the token
     * @return The owner's address
     */
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(tokenExists[_tokenId], "Token does not exist");
        return certificates[_tokenId].owner;
    }
    
    /**
     * @dev Returns all tokens owned by a specific address
     * @param _owner The address to query
     * @return Array of token IDs
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count tokens still owned by the address
        for (uint256 i = 0; i < ownerTokens[_owner].length; i++) {
            uint256 tokenId = ownerTokens[_owner][i];
            if (tokenExists[tokenId] && certificates[tokenId].owner == _owner) {
                count++;
            }
        }
        
        // Create array of current token IDs
        uint256[] memory currentTokens = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < ownerTokens[_owner].length; i++) {
            uint256 tokenId = ownerTokens[_owner][i];
            if (tokenExists[tokenId] && certificates[tokenId].owner == _owner) {
                currentTokens[index] = tokenId;
                index++;
            }
        }
        
        return currentTokens;
    }
    
    /**
     * @dev Returns all tokens owned by the caller
     * @return Array of token IDs
     */
    function getMyTokens() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < ownerTokens[msg.sender].length; i++) {
            uint256 tokenId = ownerTokens[msg.sender][i];
            if (tokenExists[tokenId] && certificates[tokenId].owner == msg.sender) {
                count++;
            }
        }
        
        uint256[] memory myTokens = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < ownerTokens[msg.sender].length; i++) {
            uint256 tokenId = ownerTokens[msg.sender][i];
            if (tokenExists[tokenId] && certificates[tokenId].owner == msg.sender) {
                myTokens[index] = tokenId;
                index++;
            }
        }
        
        return myTokens;
    }
    
    /**
     * @dev Returns the balance (number of tokens) of an address
     * @param _owner The address to query
     * @return The number of tokens owned
     */
    function balanceOf(address _owner) external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < ownerTokens[_owner].length; i++) {
            uint256 tokenId = ownerTokens[_owner][i];
            if (tokenExists[tokenId] && certificates[tokenId].owner == _owner) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Returns the total number of tokens minted (including burned)
     * @return The total supply
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }
    
    /**
     * @dev Returns the total number of existing (not burned) tokens
     * @return The count of existing tokens
     */
    function getExistingTokenCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tokenExists[i]) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Returns all existing certificates
     * @return Array of all existing certificates
     */
    function getAllCertificates() external view returns (Certificate[] memory) {
        uint256 existingCount = 0;
        
        // Count existing certificates
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tokenExists[i]) {
                existingCount++;
            }
        }
        
        // Create array of existing certificates
        Certificate[] memory allCerts = new Certificate[](existingCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tokenExists[i]) {
                allCerts[index] = certificates[i];
                index++;
            }
        }
        
        return allCerts;
    }
    
    /**
     * @dev Checks if a token exists
     * @param _tokenId The ID of the token
     * @return True if exists, false otherwise
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return tokenExists[_tokenId];
    }
    
    /**
     * @dev Returns the token URI (metadata URI)
     * @param _tokenId The ID of the token
     * @return The metadata URI
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(tokenExists[_tokenId], "Token does not exist");
        return certificates[_tokenId].metadataURI;
    }
    
    /**
     * @dev Returns the name of the NFT collection
     * @return The contract name
     */
    function name() external view returns (string memory) {
        return contractName;
    }
    
    /**
     * @dev Returns the symbol of the NFT collection
     * @return The contract symbol
     */
    function symbol() external view returns (string memory) {
        return contractSymbol;
    }
    
    /**
     * @dev Batch mints multiple certificates
     * @param _recipients Array of recipient addresses
     * @param _names Array of certificate names
     * @param _descriptions Array of certificate descriptions
     * @param _metadataURIs Array of metadata URIs
     */
    function batchMintCertificates(
        address[] memory _recipients,
        string[] memory _names,
        string[] memory _descriptions,
        string[] memory _metadataURIs
    ) external onlyOwner {
        require(_recipients.length > 0, "Recipients array cannot be empty");
        require(_recipients.length == _names.length, "Arrays length mismatch");
        require(_recipients.length == _descriptions.length, "Arrays length mismatch");
        require(_recipients.length == _metadataURIs.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            require(bytes(_names[i]).length > 0, "Name cannot be empty");
            
            totalSupply++;
            uint256 tokenId = totalSupply;
            
            certificates[tokenId] = Certificate({
                tokenId: tokenId,
                owner: _recipients[i],
                name: _names[i],
                description: _descriptions[i],
                metadataURI: _metadataURIs[i],
                mintedAt: block.timestamp,
                mintedBy: msg.sender
            });
            
            tokenExists[tokenId] = true;
            ownerTokens[_recipients[i]].push(tokenId);
            
            emit CertificateMinted(tokenId, _recipients[i], _names[i], block.timestamp);
        }
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
