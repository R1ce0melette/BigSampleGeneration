// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeMint(address to, uint256 tokenId, string calldata uri) external;
}

contract CertificateNFT {
    address public owner;
    IERC721 public nft;
    uint256 public nextTokenId;

    event CertificateMinted(address indexed to, uint256 tokenId, string uri);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _nft) {
        owner = msg.sender;
        nft = IERC721(_nft);
    }

    function mintCertificate(address to, string calldata uri) external onlyOwner {
        nft.safeMint(to, nextTokenId, uri);
        emit CertificateMinted(to, nextTokenId, uri);
        nextTokenId++;
    }
}
