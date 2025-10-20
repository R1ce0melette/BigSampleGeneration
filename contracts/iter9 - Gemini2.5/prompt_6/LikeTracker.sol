// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    // Mapping from an address to the number of likes it has received.
    mapping(address => uint256) public likesCount;

    // Mapping to track who has liked whom. 
    // The first address is the one giving the like, the second is the one receiving it.
    mapping(address => mapping(address => bool)) public hasLiked;

    // Event to be emitted when a user likes another user.
    event Liked(address indexed liker, address indexed likedUser);

    /**
     * @dev Allows a user to like another user.
     * A user cannot like themselves.
     * A user can only like another user once.
     * @param _user The address of the user to be liked.
     */
    function like(address _user) public {
        require(_user != msg.sender, "You cannot like yourself.");
        require(!hasLiked[msg.sender][_user], "You have already liked this user.");

        likesCount[_user]++;
        hasLiked[msg.sender][_user] = true;

        emit Liked(msg.sender, _user);
    }

    /**
     * @dev Retrieves the number of likes for a specific user.
     * @param _user The address of the user.
     * @return The total number of likes.
     */
    function getLikes(address _user) public view returns (uint256) {
        return likesCount[_user];
    }
}
