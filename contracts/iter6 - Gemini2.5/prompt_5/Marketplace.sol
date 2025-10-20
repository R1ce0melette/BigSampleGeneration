// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCounter;

    event ItemListed(
        uint256 indexed id,
        string name,
        uint256 price,
        address indexed seller
    );

    event ItemSold(
        uint256 indexed id,
        address indexed buyer,
        address indexed seller
    );

    function listItem(string memory _name, uint256 _price) public {
        require(_price > 0, "Price must be greater than zero");
        itemCounter++;
        items[itemCounter] = Item(
            itemCounter,
            _name,
            _price,
            payable(msg.sender),
            false
        );
        emit ItemListed(itemCounter, _name, _price, msg.sender);
    }

    function purchaseItem(uint256 _id) public payable {
        Item storage item = items[_id];
        require(_id > 0 && _id <= itemCounter, "Item does not exist");
        require(!item.isSold, "Item is already sold");
        require(msg.value == item.price, "Incorrect price paid");

        item.isSold = true;
        item.seller.transfer(msg.value);

        emit ItemSold(_id, msg.sender, item.seller);
    }
}
