// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalCertificateNFT {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address public owner;

    struct Certificate {
        uint256 tokenId;
        address owner;
        string recipientName;
        string certificateType;
        string issuer;
        string metadata;
        uint256 issuedDate;
        bool exists;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(uint256 indexed tokenId, address indexed recipient, string certificateType);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(certificates[tokenId].exists, "Token does not exist");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    function mintCertificate(
        address recipient,
        string memory recipientName,
        string memory certificateType,
        string memory issuer,
        string memory metadata
    ) external onlyOwner returns (uint256) {
        require(recipient != address(0), "Invalid recipient address");
        require(bytes(recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(certificateType).length > 0, "Certificate type cannot be empty");

        totalSupply++;
        uint256 newTokenId = totalSupply;

        certificates[newTokenId] = Certificate({
            tokenId: newTokenId,
            owner: recipient,
            recipientName: recipientName,
            certificateType: certificateType,
            issuer: issuer,
            metadata: metadata,
            issuedDate: block.timestamp,
            exists: true
        });

        tokenOwner[newTokenId] = recipient;
        ownerTokenCount[recipient]++;

        emit Transfer(address(0), recipient, newTokenId);
        emit CertificateMinted(newTokenId, recipient, certificateType);

        return newTokenId;
    }

    function transferFrom(address from, address to, uint256 tokenId) external tokenExists(tokenId) {
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(tokenOwner[tokenId] == from, "From address is not the owner");
        require(
            msg.sender == from || 
            msg.sender == tokenApprovals[tokenId] || 
            operatorApprovals[from][msg.sender],
            "Not authorized to transfer"
        );

        // Clear approvals
        delete tokenApprovals[tokenId];

        // Transfer ownership
        tokenOwner[tokenId] = to;
        certificates[tokenId].owner = to;
        ownerTokenCount[from]--;
        ownerTokenCount[to]++;

        emit Transfer(from, to, tokenId);
    }

    function approve(address approved, uint256 tokenId) external tokenExists(tokenId) {
        address tokenOwnerAddress = tokenOwner[tokenId];
        require(msg.sender == tokenOwnerAddress || operatorApprovals[tokenOwnerAddress][msg.sender], 
                "Not authorized to approve");
        require(approved != tokenOwnerAddress, "Cannot approve to current owner");

        tokenApprovals[tokenId] = approved;
        emit Approval(tokenOwnerAddress, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Cannot approve to yourself");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function ownerOf(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return tokenOwner[tokenId];
    }

    function balanceOf(address tokenOwnerAddress) external view returns (uint256) {
        require(tokenOwnerAddress != address(0), "Invalid address");
        return ownerTokenCount[tokenOwnerAddress];
    }

    function getApproved(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address tokenOwnerAddress, address operator) external view returns (bool) {
        return operatorApprovals[tokenOwnerAddress][operator];
    }

    function getCertificate(uint256 tokenId) external view tokenExists(tokenId) returns (
        uint256 id,
        address certificateOwner,
        string memory recipientName,
        string memory certificateType,
        string memory issuer,
        string memory metadata,
        uint256 issuedDate
    ) {
        Certificate memory cert = certificates[tokenId];
        return (
            cert.tokenId,
            cert.owner,
            cert.recipientName,
            cert.certificateType,
            cert.issuer,
            cert.metadata,
            cert.issuedDate
        );
    }

    function getTokensByOwner(address tokenOwnerAddress) external view returns (uint256[] memory) {
        require(tokenOwnerAddress != address(0), "Invalid address");
        
        uint256 balance = ownerTokenCount[tokenOwnerAddress];
        uint256[] memory ownedTokens = new uint256[](balance);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tokenOwner[i] == tokenOwnerAddress) {
                ownedTokens[currentIndex] = i;
                currentIndex++;
            }
        }

        return ownedTokens;
    }

    function verifyCertificate(uint256 tokenId) external view tokenExists(tokenId) returns (
        bool isValid,
        address certificateOwner,
        string memory recipientName,
        uint256 issuedDate
    ) {
        Certificate memory cert = certificates[tokenId];
        return (true, cert.owner, cert.recipientName, cert.issuedDate);
    }

    function updateMetadata(uint256 tokenId, string memory newMetadata) external onlyOwner tokenExists(tokenId) {
        require(bytes(newMetadata).length > 0, "Metadata cannot be empty");
        certificates[tokenId].metadata = newMetadata;
    }

    function burn(uint256 tokenId) external tokenExists(tokenId) {
        require(tokenOwner[tokenId] == msg.sender, "Only token owner can burn");

        address tokenOwnerAddress = tokenOwner[tokenId];
        
        delete tokenApprovals[tokenId];
        delete tokenOwner[tokenId];
        ownerTokenCount[tokenOwnerAddress]--;
        certificates[tokenId].exists = false;

        emit Transfer(tokenOwnerAddress, address(0), tokenId);
    }
}
