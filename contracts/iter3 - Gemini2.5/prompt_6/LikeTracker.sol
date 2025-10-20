// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LikeTracker
 * @dev A contract to track the number of likes each address receives.
 * Users can like another user's address only once.
 */
contract LikeTracker {
    // Mapping from an address to the number of likes it has received
    mapping(address => uint256) private _likes;
    // Mapping to track which addresses have already liked another address
    // The key is the liked address, and the value is another mapping
    // where the key is the liker's address and the value is a boolean.
    mapping(address => mapping(address => bool)) private _hasLiked;

    /**
     * @dev Emitted when an address receives a like.
     * @param likedAddress The address that was liked.
     * @param likerAddress The address that gave the like.
     */
    event Liked(address indexed likedAddress, address indexed likerAddress);

    /**
     * @dev Allows the sender to like another user's address.
     * - A user cannot like their own address.
     * - A user can only like another address once.
     * @param likedAddress The address to be liked.
     */
    function like(address likedAddress) public {
        require(likedAddress != msg.sender, "You cannot like your own address.");
        require(!_hasLiked[likedAddress][msg.sender], "You have already liked this address.");

        _likes[likedAddress]++;
        _hasLiked[likedAddress][msg.sender] = true;

        emit Liked(likedAddress, msg.sender);
    }

    /**
     * @dev Retrieves the number of likes for a given address.
     * @param userAddress The address to query for likes.
     * @return The total number of likes received by the address.
     */
    function getLikes(address userAddress) public view returns (uint256) {
        return _likes[userAddress];
    }

    /**
     * @dev Checks if a user has already liked another user's address.
     * @param likedAddress The address that might have been liked.
     * @param likerAddress The address of the potential liker.
     * @return True if `likerAddress` has liked `likedAddress`, false otherwise.
     */
    function hasUserLiked(address likedAddress, address likerAddress) public view returns (bool) {
        return _hasLiked[likedAddress][likerAddress];
    }
}
