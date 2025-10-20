// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    struct Item {
        uint id;
        string name;
        string description;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    mapping(uint => Item) public items;
    uint public itemCount;

    event ItemListed(
        uint id,
        string name,
        uint256 price,
        address indexed seller
    );

    event ItemSold(
        uint id,
        address indexed buyer
    );

    function listItem(string memory _name, string memory _description, uint256 _price) public {
        require(_price > 0, "Price must be greater than zero");
        itemCount++;
        items[itemCount] = Item(
            itemCount,
            _name,
            _description,
            _price,
            payable(msg.sender),
            false
        );
        emit ItemListed(itemCount, _name, _price, msg.sender);
    }

    function purchaseItem(uint _id) public payable {
        Item storage item = items[_id];
        require(_id > 0 && _id <= itemCount, "Item does not exist");
        require(!item.isSold, "Item is already sold");
        require(msg.value == item.price, "Incorrect price paid");
        require(msg.sender != item.seller, "Seller cannot buy their own item");

        item.isSold = true;
        item.seller.transfer(msg.value);

        emit ItemSold(_id, msg.sender);
    }
}
