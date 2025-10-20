// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LikeTracker
 * @dev A contract to track likes for addresses. Each user can like another user only once.
 */
contract LikeTracker {
    // Mapping from an address to the number of likes it has received.
    mapping(address => uint256) private _likes;

    // Mapping to ensure a user can only like another user once.
    // The key is the address of the user giving the like, and the value is a mapping
    // from the liked address to a boolean flag.
    mapping(address => mapping(address => bool)) private _hasLiked;

    /**
     * @dev Emitted when a user likes another user.
     * @param from The address of the user who gave the like.
     * @param to The address of the user who received the like.
     */
    event Liked(address indexed from, address indexed to);

    /**
     * @dev Allows the caller to like another user's address.
     * @param user The address of the user to like.
     */
    function like(address user) public {
        require(user != msg.sender, "You cannot like yourself.");
        require(!_hasLiked[msg.sender][user], "You have already liked this user.");

        _hasLiked[msg.sender][user] = true;
        _likes[user]++;

        emit Liked(msg.sender, user);
    }

    /**
     * @dev Retrieves the number of likes for a given address.
     * @param user The address to query.
     * @return The total number of likes received by the user.
     */
    function getLikes(address user) public view returns (uint256) {
        return _likes[user];
    }

    /**
     * @dev Checks if a user has already liked another user.
     * @param from The address of the user who might have given the like.
     * @param to The address of the user who might have been liked.
     * @return True if `from` has liked `to`, false otherwise.
     */
    function hasLiked(address from, address to) public view returns (bool) {
        return _hasLiked[from][to];
    }
}
