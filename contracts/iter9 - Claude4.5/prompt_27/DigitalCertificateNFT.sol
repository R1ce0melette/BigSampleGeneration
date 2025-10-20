// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalCertificateNFT {
    struct Certificate {
        uint256 tokenId;
        address owner;
        string recipientName;
        string title;
        string description;
        string issuer;
        uint256 issueDate;
        string metadataURI;
        bool exists;
    }
    
    string public name = "Digital Certificate NFT";
    string public symbol = "DCNFT";
    
    address public admin;
    uint256 public totalSupply;
    
    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        string recipientName,
        string title,
        uint256 issueDate
    );
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "Not the token owner");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Mint a new certificate NFT
     * @param _recipient The address to receive the NFT
     * @param _recipientName The name of the recipient
     * @param _title The certificate title
     * @param _description The certificate description
     * @param _issuer The issuer name
     * @param _metadataURI The URI for additional metadata
     */
    function mintCertificate(
        address _recipient,
        string memory _recipientName,
        string memory _title,
        string memory _description,
        string memory _issuer,
        string memory _metadataURI
    ) external onlyAdmin returns (uint256) {
        require(_recipient != address(0), "Invalid recipient address");
        require(bytes(_recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(_title).length > 0, "Title cannot be empty");
        
        totalSupply++;
        uint256 tokenId = totalSupply;
        
        certificates[tokenId] = Certificate({
            tokenId: tokenId,
            owner: _recipient,
            recipientName: _recipientName,
            title: _title,
            description: _description,
            issuer: _issuer,
            issueDate: block.timestamp,
            metadataURI: _metadataURI,
            exists: true
        });
        
        tokenOwner[tokenId] = _recipient;
        ownerTokenCount[_recipient]++;
        
        emit Transfer(address(0), _recipient, tokenId);
        emit CertificateMinted(tokenId, _recipient, _recipientName, _title, block.timestamp);
        
        return tokenId;
    }
    
    /**
     * @dev Batch mint certificates to multiple recipients
     * @param _recipients Array of recipient addresses
     * @param _recipientNames Array of recipient names
     * @param _titles Array of certificate titles
     * @param _descriptions Array of certificate descriptions
     * @param _issuer The issuer name (same for all)
     * @param _metadataURIs Array of metadata URIs
     */
    function batchMintCertificates(
        address[] memory _recipients,
        string[] memory _recipientNames,
        string[] memory _titles,
        string[] memory _descriptions,
        string memory _issuer,
        string[] memory _metadataURIs
    ) external onlyAdmin {
        require(_recipients.length == _recipientNames.length, "Arrays length mismatch");
        require(_recipients.length == _titles.length, "Arrays length mismatch");
        require(_recipients.length == _descriptions.length, "Arrays length mismatch");
        require(_recipients.length == _metadataURIs.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Invalid recipient address");
            
            totalSupply++;
            uint256 tokenId = totalSupply;
            
            certificates[tokenId] = Certificate({
                tokenId: tokenId,
                owner: _recipients[i],
                recipientName: _recipientNames[i],
                title: _titles[i],
                description: _descriptions[i],
                issuer: _issuer,
                issueDate: block.timestamp,
                metadataURI: _metadataURIs[i],
                exists: true
            });
            
            tokenOwner[tokenId] = _recipients[i];
            ownerTokenCount[_recipients[i]]++;
            
            emit Transfer(address(0), _recipients[i], tokenId);
            emit CertificateMinted(tokenId, _recipients[i], _recipientNames[i], _titles[i], block.timestamp);
        }
    }
    
    /**
     * @dev Transfer token to another address
     * @param _to The address to transfer to
     * @param _tokenId The token ID to transfer
     */
    function transfer(address _to, uint256 _tokenId) external {
        require(_to != address(0), "Invalid recipient address");
        require(tokenOwner[_tokenId] == msg.sender, "Not the token owner");
        require(certificates[_tokenId].exists, "Token does not exist");
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
    /**
     * @dev Transfer from one address to another (for approved operators)
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _tokenId The token ID to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_to != address(0), "Invalid recipient address");
        require(tokenOwner[_tokenId] == _from, "From address is not the owner");
        require(
            msg.sender == _from || 
            tokenApprovals[_tokenId] == msg.sender || 
            operatorApprovals[_from][msg.sender],
            "Not authorized"
        );
        
        _transfer(_from, _to, _tokenId);
    }
    
    /**
     * @dev Internal transfer function
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _tokenId The token ID to transfer
     */
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        tokenOwner[_tokenId] = _to;
        certificates[_tokenId].owner = _to;
        ownerTokenCount[_from]--;
        ownerTokenCount[_to]++;
        
        // Clear approvals
        delete tokenApprovals[_tokenId];
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    /**
     * @dev Approve an address to transfer a specific token
     * @param _approved The address to approve
     * @param _tokenId The token ID
     */
    function approve(address _approved, uint256 _tokenId) external {
        require(tokenOwner[_tokenId] == msg.sender, "Not the token owner");
        
        tokenApprovals[_tokenId] = _approved;
        
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    /**
     * @dev Set approval for all tokens owned by caller
     * @param _operator The operator address
     * @param _approved True to approve, false to revoke
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Cannot approve self");
        
        operatorApprovals[msg.sender][_operator] = _approved;
        
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    /**
     * @dev Update metadata URI for a certificate (admin only)
     * @param _tokenId The token ID
     * @param _newMetadataURI The new metadata URI
     */
    function updateMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyAdmin {
        require(certificates[_tokenId].exists, "Token does not exist");
        
        certificates[_tokenId].metadataURI = _newMetadataURI;
        
        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }
    
    /**
     * @dev Get certificate details
     * @param _tokenId The token ID
     * @return All certificate details
     */
    function getCertificate(uint256 _tokenId) external view returns (
        uint256 tokenId,
        address owner,
        string memory recipientName,
        string memory title,
        string memory description,
        string memory issuer,
        uint256 issueDate,
        string memory metadataURI
    ) {
        require(certificates[_tokenId].exists, "Token does not exist");
        
        Certificate memory cert = certificates[_tokenId];
        
        return (
            cert.tokenId,
            cert.owner,
            cert.recipientName,
            cert.title,
            cert.description,
            cert.issuer,
            cert.issueDate,
            cert.metadataURI
        );
    }
    
    /**
     * @dev Get the owner of a token
     * @param _tokenId The token ID
     * @return The owner address
     */
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(certificates[_tokenId].exists, "Token does not exist");
        return tokenOwner[_tokenId];
    }
    
    /**
     * @dev Get the balance of an owner
     * @param _owner The owner address
     * @return The number of tokens owned
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Invalid address");
        return ownerTokenCount[_owner];
    }
    
    /**
     * @dev Get approved address for a token
     * @param _tokenId The token ID
     * @return The approved address
     */
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(certificates[_tokenId].exists, "Token does not exist");
        return tokenApprovals[_tokenId];
    }
    
    /**
     * @dev Check if an operator is approved for all tokens of an owner
     * @param _owner The owner address
     * @param _operator The operator address
     * @return True if approved, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
    
    /**
     * @dev Get token URI (metadata URI)
     * @param _tokenId The token ID
     * @return The metadata URI
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(certificates[_tokenId].exists, "Token does not exist");
        return certificates[_tokenId].metadataURI;
    }
    
    /**
     * @dev Check if a token exists
     * @param _tokenId The token ID
     * @return True if exists, false otherwise
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return certificates[_tokenId].exists;
    }
    
    /**
     * @dev Transfer admin role to a new address
     * @param _newAdmin The new admin address
     */
    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        
        admin = _newAdmin;
    }
}
