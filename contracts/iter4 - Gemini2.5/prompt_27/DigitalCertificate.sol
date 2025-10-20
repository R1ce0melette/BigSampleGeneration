// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A standard interface for ERC721 non-fungible tokens.
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// A standard interface for ERC721 metadata.
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract DigitalCertificate is IERC721, IERC721Metadata {
    string public override name;
    string public override symbol;
    
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;
    uint256 private _tokenIdCounter;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    function mint(address _to, string memory _tokenURI) public {
        require(msg.sender == owner, "Only owner can mint new certificates.");
        _tokenIdCounter++;
        uint256 newItemId = _tokenIdCounter;

        _owners[newItemId] = _to;
        _balances[_to]++;
        _tokenURIs[newItemId] = _tokenURI;

        emit Transfer(address(0), _to, newItemId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address ownerAddress = _owners[tokenId];
        require(ownerAddress != address(0), "ERC721: owner query for nonexistent token");
        return ownerAddress;
    }
    
    // The following functions are boilerplate for ERC721 compliance and are not fully implemented for brevity.
    // A production contract would use a library like OpenZeppelin's ERC721.
    function approve(address to, uint256 tokenId) external override {}
    function getApproved(uint256 tokenId) external view override returns (address operator) { return address(0); }
    function setApprovalForAll(address operator, bool _approved) external override {}
    function isApprovedForAll(address, address) external view override returns (bool) { return false; }
    function transferFrom(address from, address to, uint256 tokenId) external override {}
}
