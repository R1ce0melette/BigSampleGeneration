// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract CertificateNFT {
    string public name = "CertificateNFT";
    string public symbol = "CERT";
    uint256 public nextTokenId;
    address public owner;

    struct Certificate {
        address owner;
        string tokenURI;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public ownerToTokens;

    event CertificateMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function mintCertificate(address to, string memory tokenURI) external onlyOwner {
        uint256 tokenId = nextTokenId;
        certificates[tokenId] = Certificate(to, tokenURI);
        ownerToTokens[to].push(tokenId);
        emit CertificateMinted(to, tokenId, tokenURI);
        nextTokenId++;
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return certificates[tokenId].tokenURI;
    }

    function getOwnerTokens(address user) external view returns (uint256[] memory) {
        return ownerToTokens[user];
    }
}
