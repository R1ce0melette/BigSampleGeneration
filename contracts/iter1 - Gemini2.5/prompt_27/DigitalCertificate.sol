// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Mock ERC721 and Ownable for compilation without local setup
abstract contract ERC721 {
    function _mint(address to, uint256 tokenId) internal virtual {}
    function _exists(uint256 tokenId) internal view virtual returns (bool) {}
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {}
    constructor(string memory name, string memory symbol) {}
}

abstract contract Ownable {
    address private _owner;
    constructor() { _owner = msg.sender; }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == msg.sender, "Ownable: caller is not the owner"); _; }
}

// Mock Counters for compilation without local setup
library Counters {
    struct Counter { uint256 _value; }
    function current(Counter storage counter) internal view returns (uint256) { return counter._value; }
    function increment(Counter storage counter) internal { unchecked { counter._value += 1; } }
}


contract DigitalCertificate is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping from token ID to metadata
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("DigitalCertificate", "CERT") {}

    function mintCertificate(address recipient, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
}
