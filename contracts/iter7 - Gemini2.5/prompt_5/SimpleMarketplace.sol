// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleMarketplace
 * @dev A basic marketplace for listing and purchasing items with ETH.
 */
contract SimpleMarketplace {
    // Structure to represent an item for sale
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    // Counter for generating unique item IDs
    uint256 private _itemIds;

    // Mapping from item ID to the Item struct
    mapping(uint256 => Item) public items;

    /**
     * @dev Emitted when a new item is listed.
     * @param itemId The unique ID of the item.
     * @param name The name of the item.
     * @param price The price of the item in wei.
     * @param seller The address of the seller.
     */
    event ItemListed(
        uint256 indexed itemId,
        string name,
        uint256 price,
        address indexed seller
    );

    /**
     * @dev Emitted when an item is purchased.
     * @param itemId The unique ID of the item.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param price The price of the item in wei.
     */
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

        _itemIds++;
        uint256 newItemId = _itemIds;

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
     * @dev Purchases an item.
     * @param itemId The ID of the item to purchase.
     */
    function purchaseItem(uint256 itemId) public payable {
        Item storage item = items[itemId];

        require(item.id != 0, "Item does not exist.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value >= item.price, "Incorrect payment amount.");

        item.isSold = true;
        
        // Transfer the payment to the seller
        (bool sent, ) = item.seller.call{value: item.price}("");
        require(sent, "Failed to send Ether to seller.");

        // Refund any excess amount to the buyer
        if (msg.value > item.price) {
            (bool refunded, ) = msg.sender.call{value: msg.value - item.price}("");
            require(refunded, "Failed to refund excess Ether.");
        }

        emit ItemSold(itemId, msg.sender, item.seller, item.price);
    }

    /**
     * @dev Returns the total number of items listed in the marketplace.
     * @return The total number of items.
     */
    function getItemCount() public view returns (uint256) {
        return _itemIds;
    }
}
