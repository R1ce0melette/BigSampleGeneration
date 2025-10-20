// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateNFT {
    string public name = "CertificateNFT";
    string public symbol = "CERT";
    address public owner;
    uint256 public nextTokenId;

    struct Certificate {
        address owner;
        string tokenURI;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public ownerCertificates;

    event Minted(address indexed to, uint256 indexed tokenId, string tokenURI);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(address to, string calldata tokenURI) external onlyOwner {
        certificates[nextTokenId] = Certificate(to, tokenURI);
        ownerCertificates[to].push(nextTokenId);
        emit Minted(to, nextTokenId, tokenURI);
        nextTokenId++;
    }

    function getCertificates(address user) external view returns (uint256[] memory) {
        return ownerCertificates[user];
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return certificates[tokenId].tokenURI;
    }
}
