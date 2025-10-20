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

    uint256 public nextItemId;
    mapping(uint256 => Item) public items;

    event ItemListed(uint256 id, address seller, string name, uint256 price);
    event ItemSold(uint256 id, address buyer);

    function listItem(string calldata name, uint256 price) external {
        require(price > 0, "Price must be positive");
        items[nextItemId] = Item(nextItemId, payable(msg.sender), name, price, false);
        emit ItemListed(nextItemId, msg.sender, name, price);
        nextItemId++;
    }

    function buyItem(uint256 itemId) external payable {
        Item storage item = items[itemId];
        require(!item.sold, "Already sold");
        require(msg.value == item.price, "Incorrect price");
        item.sold = true;
        item.seller.transfer(msg.value);
        emit ItemSold(itemId, msg.sender);
    }
}
