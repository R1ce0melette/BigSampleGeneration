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

    event PropertyRegistered(uint256 id, address indexed owner, string details);
    event PropertyTransferred(uint256 id, address indexed from, address indexed to);

    function registerProperty(string calldata details) external {
        properties[nextPropertyId] = Property(nextPropertyId, msg.sender, details);
        ownerProperties[msg.sender].push(nextPropertyId);
        emit PropertyRegistered(nextPropertyId, msg.sender, details);
        nextPropertyId++;
    }

    function transferProperty(uint256 propertyId, address to) external {
        Property storage prop = properties[propertyId];
        require(prop.owner == msg.sender, "Not property owner");
        prop.owner = to;
        ownerProperties[to].push(propertyId);
        // Remove from previous owner's list
        uint256[] storage props = ownerProperties[msg.sender];
        for (uint256 i = 0; i < props.length; i++) {
            if (props[i] == propertyId) {
                props[i] = props[props.length - 1];
                props.pop();
                break;
            }
        }
        emit PropertyTransferred(propertyId, msg.sender, to);
    }

    function verifyOwnership(uint256 propertyId, address user) external view returns (bool) {
        return properties[propertyId].owner == user;
    }

    function getProperties(address user) external view returns (uint256[] memory) {
        return ownerProperties[user];
    }
}
