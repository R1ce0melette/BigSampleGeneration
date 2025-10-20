// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeMint(address to, uint256 tokenId, string calldata uri) external;
}

contract CertificateNFT {
    uint256 public nextTokenId;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => address) public owners;

    event CertificateMinted(address indexed to, uint256 tokenId, string uri);

    function mint(string calldata uri) external {
        uint256 tokenId = nextTokenId;
        owners[tokenId] = msg.sender;
        tokenURIs[tokenId] = uri;
        nextTokenId++;
        emit CertificateMinted(msg.sender, tokenId, uri);
    }

    function getCertificate(uint256 tokenId) external view returns (address, string memory) {
        return (owners[tokenId], tokenURIs[tokenId]);
    }
}
