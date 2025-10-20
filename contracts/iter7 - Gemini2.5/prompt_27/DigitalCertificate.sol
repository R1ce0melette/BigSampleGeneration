// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";

/**
 * @title DigitalCertificate
 * @dev An ERC721 token contract for minting digital certificates.
 * Each certificate is a unique NFT with associated metadata.
 */
contract DigitalCertificate is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to its metadata URI.
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Sets up the contract with a name and symbol for the NFT collection.
     */
    constructor() ERC721("DigitalCertificate", "CERT") {}

    /**
     * @dev Mints a new certificate (NFT) and assigns it to a recipient.
     * The metadata for the certificate is provided as a URI.
     * Only the contract owner can mint new certificates.
     * @param _recipient The address that will receive the minted certificate.
     * @param _tokenURI A URI pointing to the JSON metadata for the certificate.
     */
    function mintCertificate(address _recipient, string memory _tokenURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_recipient, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
    }

    /**
     * @dev Overrides the base `tokenURI` function to return the specific URI for a token.
     * @param _tokenId The ID of the token to get the URI for.
     * @return The metadata URI of the token.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token ID.
     * @param _tokenId The ID of the token.
     * @param _tokenURI The URI to set.
     */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal {
        _tokenURIs[_tokenId] = _tokenURI;
    }
}
