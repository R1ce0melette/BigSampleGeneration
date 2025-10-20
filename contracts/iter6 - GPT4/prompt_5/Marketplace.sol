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

    event ItemListed(uint256 indexed id, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed id, address indexed buyer);

    function listItem(string calldata name, uint256 price) external {
        require(price > 0, "Price must be positive");
        items[nextItemId] = Item({
            id: nextItemId,
            seller: payable(msg.sender),
            name: name,
            price: price,
            sold: false
        });
        emit ItemListed(nextItemId, msg.sender, name, price);
        nextItemId++;
    }

    function purchase(uint256 itemId) external payable {
        Item storage item = items[itemId];
        require(!item.sold, "Already sold");
        require(msg.value == item.price, "Incorrect ETH amount");
        item.sold = true;
        item.seller.transfer(msg.value);
        emit ItemPurchased(itemId, msg.sender);
    }
}
