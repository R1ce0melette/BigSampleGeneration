// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/utils/Counters.sol";

contract DigitalCertificate is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct CertificateMetadata {
        string title;
        string recipientName;
        uint256 issueDate;
    }

    mapping(uint256 => CertificateMetadata) public certificateMetadata;
    string private _baseTokenURI;

    event CertificateMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        string title,
        string recipientName
    );

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function mintCertificate(
        address _recipient,
        string memory _title,
        string memory _recipientName
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_recipient, newItemId);

        certificateMetadata[newItemId] = CertificateMetadata({
            title: _title,
            recipientName: _recipientName,
            issueDate: block.timestamp
        });

        emit CertificateMinted(newItemId, _recipient, _title, _recipientName);

        return newItemId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getCertificate(uint256 _tokenId) 
        public 
        view 
        returns (string memory title, string memory recipientName, uint256 issueDate) 
    {
        require(_exists(_tokenId), "Certificate with this ID does not exist.");
        CertificateMetadata memory meta = certificateMetadata[_tokenId];
        return (meta.title, meta.recipientName, meta.issueDate);
    }
}
