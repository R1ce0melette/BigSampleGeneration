// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LikeTracker
 * @dev A contract to track likes for different addresses. Each user can like another user only once.
 */
contract LikeTracker {

    // Mapping from a user's address to the number of likes they have received.
    mapping(address => uint256) public likesReceived;

    // Mapping to track which users have already liked another user.
    // The key is the address of the user being liked, and the value is another mapping
    // where the key is the address of the liker, and the value is a boolean.
    mapping(address => mapping(address => bool)) public hasLiked;

    /**
     * @dev Event emitted when a user likes another user.
     * @param liker The address of the user who gave the like.
     * @param likedUser The address of the user who received the like.
     */
    event UserLiked(address indexed liker, address indexed likedUser);

    /**
     * @dev Allows a user to like another user's address.
     * - A user cannot like their own address.
     * - A user can only like another user once.
     * @param _userToLike The address of the user to like.
     */
    function likeUser(address _userToLike) public {
        require(_userToLike != msg.sender, "You cannot like your own address.");
        require(!hasLiked[_userToLike][msg.sender], "You have already liked this user.");

        likesReceived[_userToLike]++;
        hasLiked[_userToLike][msg.sender] = true;

        emit UserLiked(msg.sender, _userToLike);
    }

    /**
     * @dev Retrieves the number of likes a specific user has received.
     * @param _user The address of the user to query.
     * @return The total number of likes received by the user.
     */
    function getLikes(address _user) public view returns (uint256) {
        return likesReceived[_user];
    }

    /**
     * @dev Checks if a user has already liked another user.
     * @param _likedUser The address of the user who might have been liked.
     * @param _liker The address of the user who might have given the like.
     * @return A boolean indicating whether the `_liker` has liked the `_likedUser`.
     */
    function checkLikeStatus(address _likedUser, address _liker) public view returns (bool) {
        return hasLiked[_likedUser][_liker];
    }
}
