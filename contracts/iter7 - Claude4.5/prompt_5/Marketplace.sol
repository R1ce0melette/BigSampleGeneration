// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Marketplace
 * @dev A simple marketplace contract where users can list items for sale and buyers can purchase using ETH
 */
contract Marketplace {
    // Item structure
    struct Item {
        uint256 id;
        address payable seller;
        string name;
        string description;
        uint256 price;
        bool sold;
        bool exists;
    }
    
    // State variables
    uint256 public itemCount;
    mapping(uint256 => Item) public items;
    
    // Events
    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price);
    event ItemDelisted(uint256 indexed itemId, address indexed seller);
    event ItemPriceUpdated(uint256 indexed itemId, uint256 oldPrice, uint256 newPrice);
    
    /**
     * @dev List a new item for sale
     * @param name The name of the item
     * @param description The description of the item
     * @param price The price of the item in wei
     * @return itemId The ID of the newly listed item
     */
    function listItem(string memory name, string memory description, uint256 price) external returns (uint256) {
        require(bytes(name).length > 0, "Item name cannot be empty");
        require(price > 0, "Price must be greater than 0");
        
        itemCount++;
        uint256 itemId = itemCount;
        
        items[itemId] = Item({
            id: itemId,
            seller: payable(msg.sender),
            name: name,
            description: description,
            price: price,
            sold: false,
            exists: true
        });
        
        emit ItemListed(itemId, msg.sender, name, price);
        
        return itemId;
    }
    
    /**
     * @dev Purchase an item
     * @param itemId The ID of the item to purchase
     * Requirements:
     * - Item must exist and not be sold
     * - Buyer cannot be the seller
     * - Sent ETH must match the item price
     */
    function purchaseItem(uint256 itemId) external payable {
        require(items[itemId].exists, "Item does not exist");
        require(!items[itemId].sold, "Item already sold");
        require(msg.sender != items[itemId].seller, "Seller cannot buy their own item");
        require(msg.value == items[itemId].price, "Incorrect payment amount");
        
        Item storage item = items[itemId];
        item.sold = true;
        
        // Transfer funds to seller
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Transfer to seller failed");
        
        emit ItemPurchased(itemId, msg.sender, item.seller, item.price);
    }
    
    /**
     * @dev Delist an item (only seller can delist)
     * @param itemId The ID of the item to delist
     * Requirements:
     * - Item must exist
     * - Caller must be the seller
     * - Item must not be sold
     */
    function delistItem(uint256 itemId) external {
        require(items[itemId].exists, "Item does not exist");
        require(msg.sender == items[itemId].seller, "Only seller can delist item");
        require(!items[itemId].sold, "Cannot delist sold item");
        
        items[itemId].exists = false;
        
        emit ItemDelisted(itemId, msg.sender);
    }
    
    /**
     * @dev Update the price of an item (only seller can update)
     * @param itemId The ID of the item
     * @param newPrice The new price in wei
     * Requirements:
     * - Item must exist
     * - Caller must be the seller
     * - Item must not be sold
     * - New price must be greater than 0
     */
    function updatePrice(uint256 itemId, uint256 newPrice) external {
        require(items[itemId].exists, "Item does not exist");
        require(msg.sender == items[itemId].seller, "Only seller can update price");
        require(!items[itemId].sold, "Cannot update price of sold item");
        require(newPrice > 0, "Price must be greater than 0");
        
        uint256 oldPrice = items[itemId].price;
        items[itemId].price = newPrice;
        
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
     * @return sold Whether the item is sold
     * @return exists Whether the item exists
     */
    function getItem(uint256 itemId) external view returns (
        uint256 id,
        address seller,
        string memory name,
        string memory description,
        uint256 price,
        bool sold,
        bool exists
    ) {
        Item memory item = items[itemId];
        return (
            item.id,
            item.seller,
            item.name,
            item.description,
            item.price,
            item.sold,
            item.exists
        );
    }
    
    /**
     * @dev Check if an item is available for purchase
     * @param itemId The ID of the item
     * @return True if the item is available, false otherwise
     */
    function isItemAvailable(uint256 itemId) external view returns (bool) {
        return items[itemId].exists && !items[itemId].sold;
    }
    
    /**
     * @dev Get all active items (not sold and still listed)
     * Note: This is a view function and may be gas-intensive for large datasets
     * @return activeItemIds Array of active item IDs
     */
    function getActiveItems() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active items
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].exists && !items[i].sold) {
                activeCount++;
            }
        }
        
        // Create array of active item IDs
        uint256[] memory activeItemIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].exists && !items[i].sold) {
                activeItemIds[index] = i;
                index++;
            }
        }
        
        return activeItemIds;
    }
}
