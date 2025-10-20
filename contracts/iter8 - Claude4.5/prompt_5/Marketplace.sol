// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Marketplace
 * @dev Simple marketplace where users can list items for sale and buyers can purchase using ETH
 */
contract Marketplace {
    // Item structure
    struct Item {
        uint256 itemId;
        address seller;
        string name;
        string description;
        uint256 price;
        bool isAvailable;
        bool exists;
    }

    // Purchase record
    struct Purchase {
        uint256 itemId;
        address buyer;
        address seller;
        uint256 price;
        uint256 timestamp;
    }

    // State variables
    uint256 private itemIdCounter;
    mapping(uint256 => Item) public items;
    mapping(address => uint256[]) private sellerItems;
    mapping(address => Purchase[]) private buyerPurchases;
    mapping(address => Purchase[]) private sellerSales;
    
    Purchase[] private allPurchases;

    // Events
    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price, uint256 timestamp);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price, uint256 timestamp);
    event ItemPriceUpdated(uint256 indexed itemId, uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    event ItemRemoved(uint256 indexed itemId, address indexed seller, uint256 timestamp);

    // Modifiers
    modifier itemExists(uint256 itemId) {
        require(items[itemId].exists, "Item does not exist");
        _;
    }

    modifier onlyItemSeller(uint256 itemId) {
        require(items[itemId].seller == msg.sender, "Not the item seller");
        _;
    }

    modifier itemAvailable(uint256 itemId) {
        require(items[itemId].isAvailable, "Item is not available");
        _;
    }

    constructor() {
        itemIdCounter = 1;
    }

    /**
     * @dev List an item for sale
     * @param name Item name
     * @param description Item description
     * @param price Item price in wei
     * @return itemId ID of the listed item
     */
    function listItem(
        string memory name,
        string memory description,
        uint256 price
    ) public returns (uint256) {
        require(bytes(name).length > 0, "Item name cannot be empty");
        require(price > 0, "Price must be greater than 0");

        uint256 itemId = itemIdCounter;
        itemIdCounter++;

        items[itemId] = Item({
            itemId: itemId,
            seller: msg.sender,
            name: name,
            description: description,
            price: price,
            isAvailable: true,
            exists: true
        });

        sellerItems[msg.sender].push(itemId);

        emit ItemListed(itemId, msg.sender, name, price, block.timestamp);

        return itemId;
    }

    /**
     * @dev Purchase an item
     * @param itemId ID of the item to purchase
     */
    function purchaseItem(uint256 itemId) 
        public 
        payable 
        itemExists(itemId) 
        itemAvailable(itemId) 
    {
        Item storage item = items[itemId];
        require(msg.sender != item.seller, "Seller cannot buy own item");
        require(msg.value == item.price, "Incorrect payment amount");

        item.isAvailable = false;

        // Record purchase
        Purchase memory purchase = Purchase({
            itemId: itemId,
            buyer: msg.sender,
            seller: item.seller,
            price: item.price,
            timestamp: block.timestamp
        });

        buyerPurchases[msg.sender].push(purchase);
        sellerSales[item.seller].push(purchase);
        allPurchases.push(purchase);

        // Transfer funds to seller
        payable(item.seller).transfer(msg.value);

        emit ItemPurchased(itemId, msg.sender, item.seller, item.price, block.timestamp);
    }

    /**
     * @dev Update item price
     * @param itemId ID of the item
     * @param newPrice New price
     */
    function updateItemPrice(uint256 itemId, uint256 newPrice) 
        public 
        itemExists(itemId) 
        onlyItemSeller(itemId) 
        itemAvailable(itemId) 
    {
        require(newPrice > 0, "Price must be greater than 0");

        uint256 oldPrice = items[itemId].price;
        items[itemId].price = newPrice;

        emit ItemPriceUpdated(itemId, oldPrice, newPrice, block.timestamp);
    }

    /**
     * @dev Remove item from marketplace
     * @param itemId ID of the item
     */
    function removeItem(uint256 itemId) 
        public 
        itemExists(itemId) 
        onlyItemSeller(itemId) 
        itemAvailable(itemId) 
    {
        items[itemId].isAvailable = false;

        emit ItemRemoved(itemId, msg.sender, block.timestamp);
    }

    /**
     * @dev Get item details
     * @param itemId ID of the item
     * @return Item details
     */
    function getItem(uint256 itemId) 
        public 
        view 
        itemExists(itemId) 
        returns (Item memory) 
    {
        return items[itemId];
    }

    /**
     * @dev Get items listed by a seller
     * @param seller Seller address
     * @return Array of item IDs
     */
    function getItemsBySeller(address seller) public view returns (uint256[] memory) {
        return sellerItems[seller];
    }

    /**
     * @dev Get purchases made by a buyer
     * @param buyer Buyer address
     * @return Array of purchase records
     */
    function getPurchasesByBuyer(address buyer) public view returns (Purchase[] memory) {
        return buyerPurchases[buyer];
    }

    /**
     * @dev Get sales made by a seller
     * @param seller Seller address
     * @return Array of purchase records
     */
    function getSalesBySeller(address seller) public view returns (Purchase[] memory) {
        return sellerSales[seller];
    }

    /**
     * @dev Get all purchases
     * @return Array of all purchase records
     */
    function getAllPurchases() public view returns (Purchase[] memory) {
        return allPurchases;
    }

    /**
     * @dev Get all available items
     * @return Array of available item IDs
     */
    function getAvailableItems() public view returns (uint256[] memory) {
        uint256 availableCount = 0;
        
        for (uint256 i = 1; i < itemIdCounter; i++) {
            if (items[i].exists && items[i].isAvailable) {
                availableCount++;
            }
        }

        uint256[] memory availableItems = new uint256[](availableCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i < itemIdCounter; i++) {
            if (items[i].exists && items[i].isAvailable) {
                availableItems[index] = i;
                index++;
            }
        }

        return availableItems;
    }

    /**
     * @dev Get total number of items listed
     * @return Total item count
     */
    function getTotalItems() public view returns (uint256) {
        return itemIdCounter - 1;
    }

    /**
     * @dev Get total number of purchases
     * @return Total purchase count
     */
    function getTotalPurchases() public view returns (uint256) {
        return allPurchases.length;
    }

    /**
     * @dev Check if item is available
     * @param itemId ID of the item
     * @return true if available
     */
    function isItemAvailable(uint256 itemId) public view itemExists(itemId) returns (bool) {
        return items[itemId].isAvailable;
    }

    /**
     * @dev Get items by price range
     * @param minPrice Minimum price
     * @param maxPrice Maximum price
     * @return Array of item IDs
     */
    function getItemsByPriceRange(uint256 minPrice, uint256 maxPrice) public view returns (uint256[] memory) {
        require(maxPrice >= minPrice, "Invalid price range");

        uint256 count = 0;
        for (uint256 i = 1; i < itemIdCounter; i++) {
            if (items[i].exists && items[i].isAvailable && 
                items[i].price >= minPrice && items[i].price <= maxPrice) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i < itemIdCounter; i++) {
            if (items[i].exists && items[i].isAvailable && 
                items[i].price >= minPrice && items[i].price <= maxPrice) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get my listed items
     * @return Array of item IDs
     */
    function getMyListedItems() public view returns (uint256[] memory) {
        return sellerItems[msg.sender];
    }

    /**
     * @dev Get my purchases
     * @return Array of purchase records
     */
    function getMyPurchases() public view returns (Purchase[] memory) {
        return buyerPurchases[msg.sender];
    }

    /**
     * @dev Get my sales
     * @return Array of purchase records
     */
    function getMySales() public view returns (Purchase[] memory) {
        return sellerSales[msg.sender];
    }
}
