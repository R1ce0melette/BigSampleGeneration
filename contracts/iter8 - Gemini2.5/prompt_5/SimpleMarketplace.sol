// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleMarketplace
 * @dev A basic marketplace for listing and purchasing items with ETH.
 */
contract SimpleMarketplace {
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    uint256 private _itemIdCounter;
    mapping(uint256 => Item) public items;

    event ItemListed(
        uint256 indexed itemId,
        string name,
        uint256 price,
        address indexed seller
    );

    event ItemSold(
        uint256 indexed itemId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );

    /**
     * @dev Lists a new item for sale.
     * @param name The name of the item.
     * @param price The price of the item in wei.
     */
    function listItem(string memory name, uint256 price) public {
        require(bytes(name).length > 0, "Item name cannot be empty.");
        require(price > 0, "Price must be greater than zero.");

        _itemIdCounter++;
        uint256 newItemId = _itemIdCounter;

        items[newItemId] = Item({
            id: newItemId,
            name: name,
            price: price,
            seller: payable(msg.sender),
            isSold: false
        });

        emit ItemListed(newItemId, name, price, msg.sender);
    }

    /**
     * @dev Purchases an item. The buyer must send the exact price of the item.
     * @param itemId The ID of the item to purchase.
     */
    function purchaseItem(uint256 itemId) public payable {
        Item storage item = items[itemId];

        require(item.id != 0, "Item does not exist.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value == item.price, "Incorrect payment amount.");

        item.isSold = true;
        
        (bool sent, ) = item.seller.call{value: item.price}("");
        require(sent, "Failed to send Ether to seller.");

        emit ItemSold(itemId, msg.sender, item.seller, item.price);
    }

    /**
     * @dev Returns the total number of items listed in the marketplace.
     * @return The total number of items.
     */
    function getItemCount() public view returns (uint256) {
        return _itemIdCounter;
    }
}
