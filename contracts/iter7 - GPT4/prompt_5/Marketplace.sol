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

    function purchaseItem(uint256 id) external payable {
        Item storage item = items[id];
        require(!item.sold, "Item already sold");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(item.seller != address(0), "Item does not exist");
        item.sold = true;
        item.seller.transfer(msg.value);
        emit ItemPurchased(id, msg.sender);
    }

    function getItem(uint256 id) external view returns (Item memory) {
        return items[id];
    }
}
