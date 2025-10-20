// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRegistry {
    struct Property {
        uint256 id;
        address owner;
        string details;
    }

    uint256 public nextPropertyId;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;

    event PropertyRegistered(uint256 indexed id, address indexed owner, string details);
    event PropertyTransferred(uint256 indexed id, address indexed from, address indexed to);

    function registerProperty(string calldata details) external {
        require(bytes(details).length > 0, "Details required");
        properties[nextPropertyId] = Property({
            id: nextPropertyId,
            owner: msg.sender,
            details: details
        });
        ownerProperties[msg.sender].push(nextPropertyId);
        emit PropertyRegistered(nextPropertyId, msg.sender, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address to) external {
        require(properties[propertyId].owner == msg.sender, "Not property owner");
        require(to != address(0), "Invalid recipient");
        address from = msg.sender;
        properties[propertyId].owner = to;
        ownerProperties[to].push(propertyId);
        // Remove from previous owner's list
        uint256[] storage props = ownerProperties[from];
        for (uint256 i = 0; i < props.length; i++) {
            if (props[i] == propertyId) {
                props[i] = props[props.length - 1];
                props.pop();
                break;
            }
        }
        emit PropertyTransferred(propertyId, from, to);
    }

    function verifyOwnership(uint256 propertyId, address user) external view returns (bool) {
        return properties[propertyId].owner == user;
    }

    function getProperties(address user) external view returns (uint256[] memory) {
        return ownerProperties[user];
    }
}
