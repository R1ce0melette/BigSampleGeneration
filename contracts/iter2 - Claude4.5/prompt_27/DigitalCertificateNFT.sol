// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalCertificateNFT {
    string public name = "Digital Certificate";
    string public symbol = "CERT";
    
    address public owner;
    uint256 public totalSupply;
    
    struct Certificate {
        uint256 tokenId;
        string recipientName;
        string courseName;
        string issuer;
        uint256 issueDate;
        string metadataURI;
    }
    
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => bool) public tokenExists;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(uint256 indexed tokenId, address indexed recipient, string recipientName, string courseName);
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "Not the token owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function mintCertificate(
        address _recipient,
        string memory _recipientName,
        string memory _courseName,
        string memory _issuer,
        string memory _metadataURI
    ) external onlyOwner returns (uint256) {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(bytes(_recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(_courseName).length > 0, "Course name cannot be empty");
        
        totalSupply++;
        uint256 tokenId = totalSupply;
        
        tokenOwner[tokenId] = _recipient;
        balanceOf[_recipient]++;
        tokenExists[tokenId] = true;
        
        certificates[tokenId] = Certificate({
            tokenId: tokenId,
            recipientName: _recipientName,
            courseName: _courseName,
            issuer: _issuer,
            issueDate: block.timestamp,
            metadataURI: _metadataURI
        });
        
        emit Transfer(address(0), _recipient, tokenId);
        emit CertificateMinted(tokenId, _recipient, _recipientName, _courseName);
        
        return tokenId;
    }
    
    function batchMintCertificates(
        address[] calldata _recipients,
        string[] calldata _recipientNames,
        string[] calldata _courseNames,
        string memory _issuer,
        string[] calldata _metadataURIs
    ) external onlyOwner returns (uint256[] memory) {
        require(_recipients.length == _recipientNames.length, "Recipients and names length mismatch");
        require(_recipients.length == _courseNames.length, "Recipients and courses length mismatch");
        require(_recipients.length == _metadataURIs.length, "Recipients and URIs length mismatch");
        
        uint256[] memory tokenIds = new uint256[](_recipients.length);
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            tokenIds[i] = mintCertificate(
                _recipients[i],
                _recipientNames[i],
                _courseNames[i],
                _issuer,
                _metadataURIs[i]
            );
        }
        
        return tokenIds;
    }
    
    function transfer(address _to, uint256 _tokenId) external {
        require(tokenExists[_tokenId], "Token does not exist");
        require(tokenOwner[_tokenId] == msg.sender, "Not the token owner");
        require(_to != address(0), "Cannot transfer to zero address");
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(tokenExists[_tokenId], "Token does not exist");
        require(_to != address(0), "Cannot transfer to zero address");
        require(tokenOwner[_tokenId] == _from, "From address is not the owner");
        require(
            msg.sender == _from ||
            tokenApprovals[_tokenId] == msg.sender ||
            operatorApprovals[_from][msg.sender],
            "Not authorized to transfer"
        );
        
        _transfer(_from, _to, _tokenId);
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        balanceOf[_from]--;
        balanceOf[_to]++;
        tokenOwner[_tokenId] = _to;
        
        // Clear approvals
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external {
        require(tokenExists[_tokenId], "Token does not exist");
        address owner = tokenOwner[_tokenId];
        require(msg.sender == owner || operatorApprovals[owner][msg.sender], "Not authorized");
        
        tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Cannot approve yourself");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(tokenExists[_tokenId], "Token does not exist");
        return tokenApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(tokenExists[_tokenId], "Token does not exist");
        return tokenOwner[_tokenId];
    }
    
    function getCertificate(uint256 _tokenId) external view returns (
        address currentOwner,
        string memory recipientName,
        string memory courseName,
        string memory issuer,
        uint256 issueDate,
        string memory metadataURI
    ) {
        require(tokenExists[_tokenId], "Token does not exist");
        Certificate memory cert = certificates[_tokenId];
        
        return (
            tokenOwner[_tokenId],
            cert.recipientName,
            cert.courseName,
            cert.issuer,
            cert.issueDate,
            cert.metadataURI
        );
    }
    
    function updateMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyOwner {
        require(tokenExists[_tokenId], "Token does not exist");
        
        certificates[_tokenId].metadataURI = _newMetadataURI;
        
        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(tokenExists[_tokenId], "Token does not exist");
        return certificates[_tokenId].metadataURI;
    }
    
    function verifyCertificate(uint256 _tokenId, address _holder) external view returns (bool) {
        if (!tokenExists[_tokenId]) {
            return false;
        }
        return tokenOwner[_tokenId] == _holder;
    }
    
    function getCertificatesByOwner(address _owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf[_owner];
        uint256[] memory ownedTokens = new uint256[](balance);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tokenOwner[i] == _owner) {
                ownedTokens[index] = i;
                index++;
                if (index == balance) {
                    break;
                }
            }
        }
        
        return ownedTokens;
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC721 interface ID
        return interfaceId == 0x80ac58cd || 
               // ERC165 interface ID
               interfaceId == 0x01ffc9a7;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
}
