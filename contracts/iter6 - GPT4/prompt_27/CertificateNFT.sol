// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CertificateNFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    event CertificateMinted(address indexed to, uint256 indexed tokenId, string uri);

    constructor() ERC721("CertificateNFT", "CERT") {}

    function mint(address to, string calldata uri) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit CertificateMinted(to, tokenId, uri);
        nextTokenId++;
    }
}
