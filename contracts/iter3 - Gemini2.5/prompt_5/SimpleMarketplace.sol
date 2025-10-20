// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleMarketplace
 * @dev A basic marketplace for listing and purchasing items using ETH.
 */
contract SimpleMarketplace {
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    uint256 private _itemIds;
    mapping(uint256 => Item) public items;

    /**
     * @dev Emitted when a new item is listed for sale.
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
     * @dev Emitted when an item is successfully purchased.
     * @param itemId The unique ID of the item.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param price The price paid for the item.
     */
    event ItemSold(
        uint256 indexed itemId,
        address indexed buyer,
        address seller,
        uint256 price
    );

    /**
     * @dev Lists a new item for sale in the marketplace.
     * @param name The name of the item.
     * @param price The price of the item in wei.
     */
    function listItem(string memory name, uint256 price) public {
        require(bytes(name).length > 0, "Item name cannot be empty.");
        require(price > 0, "Item price must be greater than zero.");

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
     * @dev Allows a user to purchase an item from the marketplace.
     * The buyer must send enough ETH to cover the item's price.
     * @param itemId The ID of the item to purchase.
     */
    function purchaseItem(uint256 itemId) public payable {
        Item storage item = items[itemId];

        require(item.id != 0, "Item does not exist.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value >= item.price, "Insufficient funds to purchase the item.");
        require(msg.sender != item.seller, "Seller cannot purchase their own item.");

        item.isSold = true;
        
        // Transfer the funds to the seller
        (bool sent, ) = item.seller.call{value: item.price}("");
        require(sent, "Failed to send funds to the seller.");

        // Refund any excess amount sent by the buyer
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }

        emit ItemSold(itemId, msg.sender, item.seller, item.price);
    }

    /**
     * @dev Retrieves the details of a specific item.
     * @param itemId The ID of the item.
     * @return A tuple containing the item's ID, name, price, seller, and sold status.
     */
    function getItem(uint256 itemId) public view returns (uint256, string memory, uint256, address, bool) {
        Item storage item = items[itemId];
        return (item.id, item.name, item.price, item.seller, item.isSold);
    }

    /**
     * @dev Returns the total number of items listed in the marketplace.
     */
    function totalItems() public view returns (uint256) {
        return _itemIds;
    }
}
