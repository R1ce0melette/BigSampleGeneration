// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleMarketplace
 * @dev A basic marketplace for listing and purchasing items with ETH.
 */
contract SimpleMarketplace {
    
    // Structure to represent an item listed for sale.
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    // A counter to generate unique item IDs.
    uint256 private nextItemId;
    // Mapping from item ID to the Item struct.
    mapping(uint256 => Item) public items;

    /**
     * @dev Event emitted when a new item is listed.
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
     * @dev Event emitted when an item is purchased.
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
     * @param _name The name of the item.
     * @param _price The price of the item in wei.
     */
    function listItem(string memory _name, uint256 _price) public {
        require(bytes(_name).length > 0, "Item name cannot be empty.");
        require(_price > 0, "Item price must be greater than zero.");

        uint256 itemId = nextItemId;
        items[itemId] = Item({
            id: itemId,
            name: _name,
            price: _price,
            seller: payable(msg.sender),
            isSold: false
        });

        nextItemId++;
        emit ItemListed(itemId, _name, _price, msg.sender);
    }

    /**
     * @dev Purchases an item from the marketplace.
     * The buyer must send enough ETH to cover the item's price.
     * @param _itemId The ID of the item to purchase.
     */
    function purchaseItem(uint256 _itemId) public payable {
        Item storage item = items[_itemId];

        require(item.id == _itemId, "Item does not exist.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value >= item.price, "Insufficient funds to purchase the item.");
        require(item.seller != msg.sender, "Seller cannot buy their own item.");

        item.isSold = true;
        
        // Transfer the funds to the seller
        (bool sent, ) = item.seller.call{value: item.price}("");
        require(sent, "Failed to send funds to the seller.");

        // Refund any excess amount sent by the buyer
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }

        emit ItemSold(_itemId, msg.sender, item.seller, item.price);
    }

    /**
     * @dev Retrieves the details of a specific item.
     * @param _itemId The ID of the item.
     * @return A tuple containing the item's ID, name, price, seller, and sold status.
     */
    function getItem(uint256 _itemId) public view returns (uint256, string memory, uint256, address, bool) {
        Item storage item = items[_itemId];
        return (item.id, item.name, item.price, item.seller, item.isSold);
    }

    /**
     * @dev Returns the total number of items listed in the marketplace.
     * @return The total count of items.
     */
    function getItemCount() public view returns (uint256) {
        return nextItemId;
    }
}
