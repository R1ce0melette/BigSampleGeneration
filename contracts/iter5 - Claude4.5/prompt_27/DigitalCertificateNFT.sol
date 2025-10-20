// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DigitalCertificateNFT {
    string public name = "Digital Certificate NFT";
    string public symbol = "DCNFT";
    
    address public owner;
    uint256 public tokenCounter;
    uint256 public mintingFee = 0.01 ether;
    
    struct Certificate {
        uint256 tokenId;
        string certificateName;
        string recipientName;
        string issuer;
        string description;
        uint256 issueDate;
        string metadataURI;
    }
    
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CertificateMinted(uint256 indexed tokenId, address indexed recipient, string certificateName);
    
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
        string memory _certificateName,
        string memory _recipientName,
        string memory _issuer,
        string memory _description,
        string memory _metadataURI
    ) external payable {
        require(msg.value >= mintingFee, "Insufficient minting fee");
        require(_recipient != address(0), "Invalid recipient address");
        require(bytes(_certificateName).length > 0, "Certificate name cannot be empty");
        
        tokenCounter++;
        uint256 newTokenId = tokenCounter;
        
        tokenOwner[newTokenId] = _recipient;
        ownerTokenCount[_recipient]++;
        
        certificates[newTokenId] = Certificate({
            tokenId: newTokenId,
            certificateName: _certificateName,
            recipientName: _recipientName,
            issuer: _issuer,
            description: _description,
            issueDate: block.timestamp,
            metadataURI: _metadataURI
        });
        
        emit Transfer(address(0), _recipient, newTokenId);
        emit CertificateMinted(newTokenId, _recipient, _certificateName);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_to != address(0), "Invalid recipient address");
        require(tokenOwner[_tokenId] == _from, "From address is not the owner");
        require(
            msg.sender == _from || 
            msg.sender == tokenApprovals[_tokenId] || 
            operatorApprovals[_from][msg.sender],
            "Not authorized to transfer"
        );
        
        delete tokenApprovals[_tokenId];
        
        ownerTokenCount[_from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Cannot approve yourself");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist");
        return tokenApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Invalid address");
        return ownerTokenCount[_owner];
    }
    
    function getCertificate(uint256 _tokenId) external view returns (
        uint256 tokenId,
        string memory certificateName,
        string memory recipientName,
        string memory issuer,
        string memory description,
        uint256 issueDate,
        string memory metadataURI,
        address currentOwner
    ) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist");
        
        Certificate memory cert = certificates[_tokenId];
        
        return (
            cert.tokenId,
            cert.certificateName,
            cert.recipientName,
            cert.issuer,
            cert.description,
            cert.issueDate,
            cert.metadataURI,
            tokenOwner[_tokenId]
        );
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist");
        return certificates[_tokenId].metadataURI;
    }
    
    function getOwnerTokens(address _owner) external view returns (uint256[] memory) {
        uint256 balance = ownerTokenCount[_owner];
        uint256[] memory tokens = new uint256[](balance);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (tokenOwner[i] == _owner) {
                tokens[index] = i;
                index++;
            }
        }
        
        return tokens;
    }
    
    function totalSupply() external view returns (uint256) {
        return tokenCounter;
    }
    
    function setMintingFee(uint256 _newFee) external onlyOwner {
        mintingFee = _newFee;
    }
    
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC165 interface ID
        return interfaceId == 0x01ffc9a7 || 
               // ERC721 interface ID
               interfaceId == 0x80ac58cd ||
               // ERC721Metadata interface ID
               interfaceId == 0x5b5e139f;
    }
}
