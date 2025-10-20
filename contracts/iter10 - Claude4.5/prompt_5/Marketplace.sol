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

    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price);
    event ItemRemoved(uint256 indexed itemId, address indexed seller);

    function listItem(string memory name, string memory description, uint256 price) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(price > 0, "Price must be greater than 0");

        itemCount++;
        items[itemCount] = Item({
            id: itemCount,
            seller: payable(msg.sender),
            name: name,
            description: description,
            price: price,
            available: true
        });

        emit ItemListed(itemCount, msg.sender, name, price);
    }

    function purchaseItem(uint256 itemId) external payable {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item storage item = items[itemId];
        require(item.available, "Item is not available");
        require(msg.value == item.price, "Incorrect payment amount");
        require(msg.sender != item.seller, "Seller cannot purchase their own item");

        item.available = false;

        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Payment to seller failed");

        emit ItemPurchased(itemId, msg.sender, item.seller, item.price);
    }

    function removeItem(uint256 itemId) external {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item storage item = items[itemId];
        require(msg.sender == item.seller, "Only seller can remove the item");
        require(item.available, "Item is already sold or removed");

        item.available = false;

        emit ItemRemoved(itemId, msg.sender);
    }

    function getItem(uint256 itemId) external view returns (
        uint256 id,
        address seller,
        string memory name,
        string memory description,
        uint256 price,
        bool available
    ) {
        require(itemId > 0 && itemId <= itemCount, "Item does not exist");
        Item memory item = items[itemId];
        return (item.id, item.seller, item.name, item.description, item.price, item.available);
    }

    function getAvailableItems() external view returns (uint256[] memory) {
        uint256 availableCount = 0;
        
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].available) {
                availableCount++;
            }
        }

        uint256[] memory availableItemIds = new uint256[](availableCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].available) {
                availableItemIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return availableItemIds;
    }
}
