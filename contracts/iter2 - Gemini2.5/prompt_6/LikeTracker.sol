// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikeTracker {
    // Mapping from an address to the number of likes it has received
    mapping(address => uint256) public likesReceived;

    // Mapping to track who has liked whom. 
    // The first address is the liker, the second is the one being liked.
    mapping(address => mapping(address => bool)) public hasLiked;

    event Liked(address indexed liker, address indexed liked);

    /**
     * @dev Allows a user to like another address. A user cannot like themselves,
     * and can only like another specific address once.
     * @param _userToLike The address of the user to be liked.
     */
    function likeUser(address _userToLike) public {
        require(_userToLike != msg.sender, "You cannot like yourself.");
        require(!hasLiked[msg.sender][_userToLike], "You have already liked this user.");

        likesReceived[_userToLike]++;
        hasLiked[msg.sender][_userToLike] = true;

        emit Liked(msg.sender, _userToLike);
    }

    /**
     * @dev Retrieves the number of likes a specific user has received.
     * @param _user The address of the user.
     * @return The total number of likes received by the user.
     */
    function getLikes(address _user) public view returns (uint256) {
        return likesReceived[_user];
    }
}
