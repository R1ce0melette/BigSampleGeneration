// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockNFT
 * @dev A simple ERC-721 contract for testing the Dutch auction
 */
contract MockNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    
    constructor() ERC721("MockNFT", "MNFT") Ownable(msg.sender) {}
    
    /**
     * @dev Mint a new NFT to the specified address
     * @param to Address to mint the NFT to
     * @return tokenId The ID of the newly minted token
     */
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _mint(to, tokenId);
        return tokenId;
    }
    
    /**
     * @dev Mint a specific token ID to the specified address
     * @param to Address to mint the NFT to
     * @param tokenId Specific token ID to mint
     */
    function mintWithId(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}