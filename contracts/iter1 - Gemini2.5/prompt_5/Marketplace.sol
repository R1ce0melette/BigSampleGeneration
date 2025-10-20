// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    struct Item {
        uint256 id;
        string name;
        string description;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCounter;

    event ItemListed(
        uint256 id,
        string name,
        uint256 price,
        address seller
    );

    event ItemSold(
        uint256 id,
        string name,
        uint256 price,
        address buyer
    );

    function listItem(string memory _name, string memory _description, uint256 _price) public {
        require(_price > 0, "Price must be greater than zero");
        itemCounter++;
        items[itemCounter] = Item(
            itemCounter,
            _name,
            _description,
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
        require(msg.value >= item.price, "Insufficient funds to purchase");

        item.isSold = true;
        item.seller.transfer(item.price);

        emit ItemSold(_id, item.name, item.price, msg.sender);
    }

    function getItem(uint256 _id) public view returns (uint256, string memory, string memory, uint256, address, bool) {
        Item memory item = items[_id];
        return (item.id, item.name, item.description, item.price, item.seller, item.isSold);
    }
}
