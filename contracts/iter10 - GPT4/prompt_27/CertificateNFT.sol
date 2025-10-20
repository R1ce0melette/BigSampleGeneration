// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeMint(address to, uint256 tokenId, string calldata uri) external;
}

contract CertificateNFT {
    address public owner;
    uint256 public nextTokenId;
    mapping(uint256 => string) public tokenURIs;

    event CertificateMinted(address indexed to, uint256 indexed tokenId, string uri);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(address to, string calldata uri) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(bytes(uri).length > 0, "URI required");
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        tokenURIs[tokenId] = uri;
        emit CertificateMinted(to, tokenId, uri);
        // This contract does not implement ERC721, so minting logic is just for demonstration.
        // In a real contract, inherit from ERC721 and call _safeMint(to, tokenId) and _setTokenURI(tokenId, uri).
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURIs[tokenId];
    }
}
