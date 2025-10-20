// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    
    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price);
    event ItemRemoved(uint256 indexed itemId, address indexed seller);
    
    function listItem(string memory _name, string memory _description, uint256 _price) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_price > 0, "Price must be greater than zero");
        
        itemCount++;
        
        items[itemCount] = Item({
            id: itemCount,
            seller: payable(msg.sender),
            name: _name,
            description: _description,
            price: _price,
            isAvailable: true
        });
        
        emit ItemListed(itemCount, msg.sender, _name, _price);
    }
    
    function purchaseItem(uint256 _itemId) external payable {
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        
        Item storage item = items[_itemId];
        
        require(item.isAvailable, "Item is not available");
        require(msg.value == item.price, "Incorrect payment amount");
        require(msg.sender != item.seller, "Seller cannot buy their own item");
        
        item.isAvailable = false;
        
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Payment to seller failed");
        
        emit ItemPurchased(_itemId, msg.sender, item.seller, item.price);
    }
    
    function removeItem(uint256 _itemId) external {
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        
        Item storage item = items[_itemId];
        
        require(msg.sender == item.seller, "Only seller can remove item");
        require(item.isAvailable, "Item is already sold or removed");
        
        item.isAvailable = false;
        
        emit ItemRemoved(_itemId, msg.sender);
    }
    
    function getItem(uint256 _itemId) external view returns (
        uint256 id,
        address seller,
        string memory name,
        string memory description,
        uint256 price,
        bool isAvailable
    ) {
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        
        Item memory item = items[_itemId];
        
        return (
            item.id,
            item.seller,
            item.name,
            item.description,
            item.price,
            item.isAvailable
        );
    }
    
    function getAvailableItems() external view returns (uint256[] memory) {
        uint256 availableCount = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].isAvailable) {
                availableCount++;
            }
        }
        
        uint256[] memory availableItemIds = new uint256[](availableCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].isAvailable) {
                availableItemIds[index] = i;
                index++;
            }
        }
        
        return availableItemIds;
    }
}
