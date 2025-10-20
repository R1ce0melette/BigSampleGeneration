// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    struct Item {
        uint256 id;
        address payable seller;
        string name;
        string description;
        uint256 price;
        bool available;
    }
    
    uint256 public itemCount;
    mapping(uint256 => Item) public items;
    
    // Events
    event ItemListed(
        uint256 indexed itemId,
        address indexed seller,
        string name,
        uint256 price
    );
    event ItemPurchased(
        uint256 indexed itemId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    event ItemRemoved(uint256 indexed itemId, address indexed seller);
    event ItemPriceUpdated(uint256 indexed itemId, uint256 oldPrice, uint256 newPrice);
    
    /**
     * @dev List a new item for sale
     * @param _name The name of the item
     * @param _description The description of the item
     * @param _price The price of the item in wei
     */
    function listItem(
        string memory _name,
        string memory _description,
        uint256 _price
    ) external {
        require(bytes(_name).length > 0, "Item name cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        
        itemCount++;
        
        items[itemCount] = Item({
            id: itemCount,
            seller: payable(msg.sender),
            name: _name,
            description: _description,
            price: _price,
            available: true
        });
        
        emit ItemListed(itemCount, msg.sender, _name, _price);
    }
    
    /**
     * @dev Purchase an item
     * @param _itemId The ID of the item to purchase
     */
    function purchaseItem(uint256 _itemId) external payable {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        
        require(item.available, "Item is not available");
        require(msg.value == item.price, "Incorrect payment amount");
        require(msg.sender != item.seller, "Seller cannot purchase own item");
        
        item.available = false;
        
        // Transfer payment to seller
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Payment transfer failed");
        
        emit ItemPurchased(_itemId, msg.sender, item.seller, item.price);
    }
    
    /**
     * @dev Remove an item from the marketplace
     * @param _itemId The ID of the item to remove
     */
    function removeItem(uint256 _itemId) external {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        
        require(msg.sender == item.seller, "Only seller can remove the item");
        require(item.available, "Item is not available");
        
        item.available = false;
        
        emit ItemRemoved(_itemId, msg.sender);
    }
    
    /**
     * @dev Update the price of an item
     * @param _itemId The ID of the item
     * @param _newPrice The new price in wei
     */
    function updatePrice(uint256 _itemId, uint256 _newPrice) external {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        require(_newPrice > 0, "Price must be greater than 0");
        
        Item storage item = items[_itemId];
        
        require(msg.sender == item.seller, "Only seller can update the price");
        require(item.available, "Item is not available");
        
        uint256 oldPrice = item.price;
        item.price = _newPrice;
        
        emit ItemPriceUpdated(_itemId, oldPrice, _newPrice);
    }
    
    /**
     * @dev Get item details
     * @param _itemId The ID of the item
     * @return id The item ID
     * @return seller The seller address
     * @return name The item name
     * @return description The item description
     * @return price The item price
     * @return available Whether the item is available
     */
    function getItem(uint256 _itemId) external view returns (
        uint256 id,
        address seller,
        string memory name,
        string memory description,
        uint256 price,
        bool available
    ) {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item memory item = items[_itemId];
        
        return (
            item.id,
            item.seller,
            item.name,
            item.description,
            item.price,
            item.available
        );
    }
    
    /**
     * @dev Get all available items (up to a limit)
     * @param _limit Maximum number of items to return
     * @return An array of item IDs that are available
     */
    function getAvailableItems(uint256 _limit) external view returns (uint256[] memory) {
        uint256 availableCount = 0;
        
        // Count available items
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].available) {
                availableCount++;
            }
        }
        
        // Determine actual size
        uint256 size = availableCount < _limit ? availableCount : _limit;
        uint256[] memory availableItems = new uint256[](size);
        
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCount && index < size; i++) {
            if (items[i].available) {
                availableItems[index] = i;
                index++;
            }
        }
        
        return availableItems;
    }
}
