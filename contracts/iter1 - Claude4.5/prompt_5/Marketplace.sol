// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Marketplace
 * @dev A simple marketplace contract where users can list items for sale and buyers can purchase using ETH
 */
contract Marketplace {
    struct Item {
        uint256 id;
        string name;
        string description;
        uint256 price;
        address payable seller;
        bool isAvailable;
    }
    
    uint256 private itemCounter;
    mapping(uint256 => Item) public items;
    
    event ItemListed(
        uint256 indexed itemId,
        string name,
        uint256 price,
        address indexed seller
    );
    
    event ItemPurchased(
        uint256 indexed itemId,
        string name,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );
    
    event ItemRemoved(uint256 indexed itemId, address indexed seller);
    
    event PriceUpdated(uint256 indexed itemId, uint256 oldPrice, uint256 newPrice);
    
    /**
     * @dev List a new item for sale
     * @param name Name of the item
     * @param description Description of the item
     * @param price Price in wei
     * @return itemId The ID of the newly listed item
     */
    function listItem(
        string memory name,
        string memory description,
        uint256 price
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Item name cannot be empty");
        require(price > 0, "Price must be greater than 0");
        
        itemCounter++;
        uint256 itemId = itemCounter;
        
        items[itemId] = Item({
            id: itemId,
            name: name,
            description: description,
            price: price,
            seller: payable(msg.sender),
            isAvailable: true
        });
        
        emit ItemListed(itemId, name, price, msg.sender);
        
        return itemId;
    }
    
    /**
     * @dev Purchase an item
     * @param itemId The ID of the item to purchase
     */
    function purchaseItem(uint256 itemId) external payable {
        Item storage item = items[itemId];
        
        require(item.id != 0, "Item does not exist");
        require(item.isAvailable, "Item is not available");
        require(msg.value == item.price, "Incorrect payment amount");
        require(msg.sender != item.seller, "Seller cannot buy their own item");
        
        item.isAvailable = false;
        
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Payment transfer failed");
        
        emit ItemPurchased(itemId, item.name, item.price, item.seller, msg.sender);
    }
    
    /**
     * @dev Remove an item from the marketplace
     * @param itemId The ID of the item to remove
     */
    function removeItem(uint256 itemId) external {
        Item storage item = items[itemId];
        
        require(item.id != 0, "Item does not exist");
        require(item.seller == msg.sender, "Only seller can remove the item");
        require(item.isAvailable, "Item is not available");
        
        item.isAvailable = false;
        
        emit ItemRemoved(itemId, msg.sender);
    }
    
    /**
     * @dev Update the price of an item
     * @param itemId The ID of the item
     * @param newPrice The new price in wei
     */
    function updatePrice(uint256 itemId, uint256 newPrice) external {
        Item storage item = items[itemId];
        
        require(item.id != 0, "Item does not exist");
        require(item.seller == msg.sender, "Only seller can update the price");
        require(item.isAvailable, "Item is not available");
        require(newPrice > 0, "Price must be greater than 0");
        
        uint256 oldPrice = item.price;
        item.price = newPrice;
        
        emit PriceUpdated(itemId, oldPrice, newPrice);
    }
    
    /**
     * @dev Get item details
     * @param itemId The ID of the item
     * @return id Item ID
     * @return name Item name
     * @return description Item description
     * @return price Item price
     * @return seller Seller address
     * @return isAvailable Availability status
     */
    function getItem(uint256 itemId) external view returns (
        uint256 id,
        string memory name,
        string memory description,
        uint256 price,
        address seller,
        bool isAvailable
    ) {
        Item memory item = items[itemId];
        require(item.id != 0, "Item does not exist");
        
        return (
            item.id,
            item.name,
            item.description,
            item.price,
            item.seller,
            item.isAvailable
        );
    }
    
    /**
     * @dev Get the total number of items listed
     * @return The total number of items
     */
    function getTotalItems() external view returns (uint256) {
        return itemCounter;
    }
    
    /**
     * @dev Check if an item is available
     * @param itemId The ID of the item
     * @return Whether the item is available
     */
    function isItemAvailable(uint256 itemId) external view returns (bool) {
        require(items[itemId].id != 0, "Item does not exist");
        return items[itemId].isAvailable;
    }
    
    /**
     * @dev Get all items listed by a specific seller
     * @param seller The address of the seller
     * @return itemIds Array of item IDs listed by the seller
     */
    function getItemsBySeller(address seller) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count items by seller
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].seller == seller && items[i].id != 0) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory itemIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].seller == seller && items[i].id != 0) {
                itemIds[index] = i;
                index++;
            }
        }
        
        return itemIds;
    }
    
    /**
     * @dev Get all available items
     * @return itemIds Array of available item IDs
     */
    function getAvailableItems() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count available items
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].isAvailable && items[i].id != 0) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory itemIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].isAvailable && items[i].id != 0) {
                itemIds[index] = i;
                index++;
            }
        }
        
        return itemIds;
    }
}
