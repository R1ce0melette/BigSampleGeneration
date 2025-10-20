// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleMarketplace {
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    event ItemListed(
        uint256 id,
        string name,
        uint256 price,
        address indexed seller
    );

    event ItemSold(
        uint256 id,
        string name,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );

    function listItem(string memory _name, uint256 _price) public {
        require(_price > 0, "Price must be greater than zero.");
        itemCount++;
        items[itemCount] = Item(itemCount, _name, _price, payable(msg.sender), false);
        emit ItemListed(itemCount, _name, _price, msg.sender);
    }

    function purchaseItem(uint256 _id) public payable {
        Item storage item = items[_id];
        require(_id > 0 && _id <= itemCount, "Item does not exist.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value == item.price, "Incorrect price paid.");
        require(msg.sender != item.seller, "Seller cannot buy their own item.");

        item.isSold = true;
        item.seller.transfer(msg.value);

        emit ItemSold(_id, item.name, item.price, item.seller, msg.sender);
    }
}
