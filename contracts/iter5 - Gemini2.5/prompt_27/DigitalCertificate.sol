// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
 * @title DigitalCertificate
 * @dev An ERC721 token contract for minting digital certificates.
 */
contract DigitalCertificate is ERC721, Ownable {
    
    uint256 private _nextTokenId;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("DigitalCertificate", "CERT") {}

    /**
     * @dev Mints a new certificate and assigns it to a recipient.
     * @param _recipient The address to receive the certificate.
     * @param _tokenURI The metadata URI for the certificate.
     */
    function mintCertificate(address _recipient, string memory _tokenURI) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Sets the token URI for a given token ID.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Returns the token URI for a given token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
}
