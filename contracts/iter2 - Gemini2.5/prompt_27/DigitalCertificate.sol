// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DigitalCertificate is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event CertificateMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);

    constructor() ERC721("DigitalCertificate", "CERT") Ownable(msg.sender) {}

    /**
     * @dev Mints a new digital certificate (NFT) and assigns it to an owner.
     * @param _owner The address that will own the minted certificate.
     * @param _tokenURI A string containing the metadata URI for the certificate.
     */
    function mintCertificate(address _owner, string memory _tokenURI) public onlyOwner {
        require(_owner != address(0), "Owner address cannot be zero.");
        
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_owner, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        emit CertificateMinted(newTokenId, _owner, _tokenURI);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
