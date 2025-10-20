// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Marketplace
 * @dev A simple marketplace where users can list items for sale and buyers can purchase using ETH
 */
contract Marketplace {
    struct Item {
        uint256 id;
        address payable seller;
        string name;
        string description;
        uint256 price;
        bool isSold;
        bool isActive;
    }
    
    uint256 public itemCount;
    mapping(uint256 => Item) public items;
    
    // Events
    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price);
    event ItemRemoved(uint256 indexed itemId, address indexed seller);
    event ItemUpdated(uint256 indexed itemId, string name, string description, uint256 price);
    
    /**
     * @dev Lists a new item for sale
     * @param _name The name of the item
     * @param _description The description of the item
     * @param _price The price of the item in wei
     */
    function listItem(
        string memory _name,
        string memory _description,
        uint256 _price
    ) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        
        itemCount++;
        
        items[itemCount] = Item({
            id: itemCount,
            seller: payable(msg.sender),
            name: _name,
            description: _description,
            price: _price,
            isSold: false,
            isActive: true
        });
        
        emit ItemListed(itemCount, msg.sender, _name, _price);
    }
    
    /**
     * @dev Allows a buyer to purchase an item
     * @param _itemId The ID of the item to purchase
     */
    function purchaseItem(uint256 _itemId) external payable {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        
        require(item.isActive, "Item is not active");
        require(!item.isSold, "Item already sold");
        require(msg.sender != item.seller, "Seller cannot buy their own item");
        require(msg.value == item.price, "Incorrect payment amount");
        
        item.isSold = true;
        item.isActive = false;
        
        // Transfer payment to seller
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Payment transfer failed");
        
        emit ItemPurchased(_itemId, msg.sender, item.seller, item.price);
    }
    
    /**
     * @dev Allows the seller to remove their listing
     * @param _itemId The ID of the item to remove
     */
    function removeItem(uint256 _itemId) external {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item storage item = items[_itemId];
        
        require(msg.sender == item.seller, "Only seller can remove the item");
        require(item.isActive, "Item is not active");
        require(!item.isSold, "Cannot remove sold item");
        
        item.isActive = false;
        
        emit ItemRemoved(_itemId, msg.sender);
    }
    
    /**
     * @dev Allows the seller to update their listing
     * @param _itemId The ID of the item to update
     * @param _name The new name of the item
     * @param _description The new description of the item
     * @param _price The new price of the item
     */
    function updateItem(
        uint256 _itemId,
        string memory _name,
        string memory _description,
        uint256 _price
    ) external {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        
        Item storage item = items[_itemId];
        
        require(msg.sender == item.seller, "Only seller can update the item");
        require(item.isActive, "Item is not active");
        require(!item.isSold, "Cannot update sold item");
        
        item.name = _name;
        item.description = _description;
        item.price = _price;
        
        emit ItemUpdated(_itemId, _name, _description, _price);
    }
    
    /**
     * @dev Returns the details of an item
     * @param _itemId The ID of the item
     * @return Item details
     */
    function getItem(uint256 _itemId) external view returns (
        uint256 id,
        address seller,
        string memory name,
        string memory description,
        uint256 price,
        bool isSold,
        bool isActive
    ) {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        
        Item memory item = items[_itemId];
        
        return (
            item.id,
            item.seller,
            item.name,
            item.description,
            item.price,
            item.isSold,
            item.isActive
        );
    }
    
    /**
     * @dev Returns all active items
     * @return Array of item IDs that are active
     */
    function getActiveItems() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active items
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].isActive && !items[i].isSold) {
                activeCount++;
            }
        }
        
        // Create array of active item IDs
        uint256[] memory activeItems = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].isActive && !items[i].isSold) {
                activeItems[index] = i;
                index++;
            }
        }
        
        return activeItems;
    }
    
    /**
     * @dev Returns items listed by a specific seller
     * @param _seller The address of the seller
     * @return Array of item IDs listed by the seller
     */
    function getItemsBySeller(address _seller) external view returns (uint256[] memory) {
        uint256 sellerItemCount = 0;
        
        // Count seller's items
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].seller == _seller) {
                sellerItemCount++;
            }
        }
        
        // Create array of seller's item IDs
        uint256[] memory sellerItems = new uint256[](sellerItemCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].seller == _seller) {
                sellerItems[index] = i;
                index++;
            }
        }
        
        return sellerItems;
    }
}
