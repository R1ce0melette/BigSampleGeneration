// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/DutchAuction.sol";
import "../src/MockNFT.sol";

/**
 * @title DeployDutchAuction
 * @dev Deployment script for the Dutch auction contract
 */
contract DeployDutchAuction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockNFT for testing
        MockNFT nft = new MockNFT();
        console.log("MockNFT deployed at:", address(nft));
        
        // Mint an NFT
        uint256 tokenId = nft.mint(deployer);
        console.log("Minted NFT with ID:", tokenId);
        
        // Deploy Dutch Auction
        uint256 startingPrice = 10 ether;
        uint256 reservePrice = 1 ether;
        uint256 duration = 24 hours; // 24 hour auction
        
        DutchAuction auction = new DutchAuction(
            address(nft),
            tokenId,
            startingPrice,
            reservePrice,
            duration
        );
        
        console.log("DutchAuction deployed at:", address(auction));
        console.log("Starting price:", startingPrice);
        console.log("Reserve price:", reservePrice);
        console.log("Duration:", duration);
        
        // Approve the auction to transfer the NFT
        nft.approve(address(auction), tokenId);
        console.log("NFT approved for auction");
        
        vm.stopBroadcast();
    }
}