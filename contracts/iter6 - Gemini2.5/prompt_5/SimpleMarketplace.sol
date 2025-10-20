// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleMarketplace {
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
        address indexed seller
    );

    event ItemSold(
        uint256 id,
        address indexed buyer
    );

    function listItem(string memory _name, string memory _description, uint256 _price) external {
        require(_price > 0, "Price must be greater than zero.");
        
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

    function purchaseItem(uint256 _id) external payable {
        Item storage item = items[_id];

        require(_id > 0 && _id <= itemCounter, "Item does not exist.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value == item.price, "Incorrect price paid.");

        item.isSold = true;
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Transfer failed.");

        emit ItemSold(_id, msg.sender);
    }
}
