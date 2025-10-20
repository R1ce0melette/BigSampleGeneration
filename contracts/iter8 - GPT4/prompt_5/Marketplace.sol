// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    struct Item {
        uint256 id;
        address payable seller;
        string name;
        uint256 price;
        bool sold;
    }

    uint256 public itemCount;
    mapping(uint256 => Item) public items;

    event ItemListed(uint256 indexed id, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed id, address indexed buyer, uint256 price);

    function listItem(string calldata name, uint256 price) external {
        require(price > 0, "Price must be positive");
        itemCount++;
        items[itemCount] = Item(itemCount, payable(msg.sender), name, price, false);
        emit ItemListed(itemCount, msg.sender, name, price);
    }

    function purchaseItem(uint256 id) external payable {
        Item storage item = items[id];
        require(item.id != 0, "Item does not exist");
        require(!item.sold, "Item already sold");
        require(msg.value == item.price, "Incorrect ETH sent");
        item.sold = true;
        item.seller.transfer(msg.value);
        emit ItemPurchased(id, msg.sender, item.price);
    }
}
