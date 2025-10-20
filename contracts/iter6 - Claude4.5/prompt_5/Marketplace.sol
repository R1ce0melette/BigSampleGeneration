// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Marketplace
 * @dev A simple marketplace contract where users can list items for sale and buyers can purchase using ETH
 */
contract Marketplace {
    struct Item {
        uint256 id;
        address payable seller;
        string name;
        string description;
        uint256 price;
        bool isAvailable;
    }
    
    uint256 public itemCount;
    mapping(uint256 => Item) public items;
    
    // Events
    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price);
    event ItemRemoved(uint256 indexed itemId, address indexed seller);
    event ItemPriceUpdated(uint256 indexed itemId, uint256 oldPrice, uint256 newPrice);
    
    /**
     * @dev List a new item for sale
     * @param name The name of the item
     * @param description The description of the item
     * @param price The price of the item in wei
     */
    function listItem(string memory name, string memory description, uint256 price) external {
        require(bytes(name).length > 0, "Item name cannot be empty");
        require(price > 0, "Price must be greater than 0");
        
        itemCount++;
        
        items[itemCount] = Item({
            id: itemCount,
            seller: payable(msg.sender),
            name: name,
            description: description,
            price: price,
            isAvailable: true
        });
        
        emit ItemListed(itemCount, msg.sender, name, price);
    }
    
    /**
     * @dev Purchase an item
     * @param itemId The ID of the item to purchase
     */
    function purchaseItem(uint256 itemId) external payable {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item storage item = items[itemId];
        
        require(item.isAvailable, "Item is not available");
        require(msg.value == item.price, "Incorrect payment amount");
        require(msg.sender != item.seller, "Seller cannot buy their own item");
        
        // Mark item as unavailable
        item.isAvailable = false;
        
        // Transfer payment to seller
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Transfer to seller failed");
        
        emit ItemPurchased(itemId, msg.sender, item.seller, item.price);
    }
    
    /**
     * @dev Remove an item from the marketplace
     * @param itemId The ID of the item to remove
     */
    function removeItem(uint256 itemId) external {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item storage item = items[itemId];
        
        require(msg.sender == item.seller, "Only seller can remove the item");
        require(item.isAvailable, "Item is already sold or removed");
        
        item.isAvailable = false;
        
        emit ItemRemoved(itemId, msg.sender);
    }
    
    /**
     * @dev Update the price of an item
     * @param itemId The ID of the item
     * @param newPrice The new price in wei
     */
    function updatePrice(uint256 itemId, uint256 newPrice) external {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item storage item = items[itemId];
        
        require(msg.sender == item.seller, "Only seller can update the price");
        require(item.isAvailable, "Item is not available");
        require(newPrice > 0, "Price must be greater than 0");
        
        uint256 oldPrice = item.price;
        item.price = newPrice;
        
        emit ItemPriceUpdated(itemId, oldPrice, newPrice);
    }
    
    /**
     * @dev Get item details
     * @param itemId The ID of the item
     * @return id The item ID
     * @return seller The seller's address
     * @return name The item name
     * @return description The item description
     * @return price The item price
     * @return isAvailable Whether the item is available
     */
    function getItem(uint256 itemId) external view returns (
        uint256 id,
        address seller,
        string memory name,
        string memory description,
        uint256 price,
        bool isAvailable
    ) {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item memory item = items[itemId];
        
        return (
            item.id,
            item.seller,
            item.name,
            item.description,
            item.price,
            item.isAvailable
        );
    }
    
    /**
     * @dev Get all available items
     * @return availableItems Array of available item IDs
     */
    function getAvailableItems() external view returns (uint256[] memory) {
        // First, count available items
        uint256 availableCount = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].isAvailable) {
                availableCount++;
            }
        }
        
        // Create array and populate with available item IDs
        uint256[] memory availableItems = new uint256[](availableCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].isAvailable) {
                availableItems[index] = i;
                index++;
            }
        }
        
        return availableItems;
    }
    
    /**
     * @dev Get all items listed by a specific seller
     * @param seller The seller's address
     * @return sellerItems Array of item IDs listed by the seller
     */
    function getItemsBySeller(address seller) external view returns (uint256[] memory) {
        // First, count items by seller
        uint256 sellerItemCount = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].seller == seller) {
                sellerItemCount++;
            }
        }
        
        // Create array and populate with seller's item IDs
        uint256[] memory sellerItems = new uint256[](sellerItemCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].seller == seller) {
                sellerItems[index] = i;
                index++;
            }
        }
        
        return sellerItems;
    }
}
