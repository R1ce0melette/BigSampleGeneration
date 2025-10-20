// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LikeTracker
 * @dev Contract that tracks likes each address receives, users can like others once
 */
contract LikeTracker {
    // State variables
    mapping(address => uint256) private likeCount;
    mapping(address => mapping(address => bool)) private hasLiked;
    mapping(address => address[]) private likedBy;
    mapping(address => address[]) private likedUsers;
    
    address[] private usersWithLikes;
    mapping(address => bool) private hasReceivedLikes;

    // Events
    event Liked(address indexed liker, address indexed liked, uint256 timestamp);
    event Unliked(address indexed unliker, address indexed unliked, uint256 timestamp);

    /**
     * @dev Like another user
     * @param user Address to like
     */
    function like(address user) public {
        require(user != address(0), "Invalid address");
        require(user != msg.sender, "Cannot like yourself");
        require(!hasLiked[msg.sender][user], "Already liked this user");

        hasLiked[msg.sender][user] = true;
        likeCount[user]++;
        likedBy[user].push(msg.sender);
        likedUsers[msg.sender].push(user);

        if (!hasReceivedLikes[user]) {
            usersWithLikes.push(user);
            hasReceivedLikes[user] = true;
        }

        emit Liked(msg.sender, user, block.timestamp);
    }

    /**
     * @dev Unlike a user
     * @param user Address to unlike
     */
    function unlike(address user) public {
        require(user != address(0), "Invalid address");
        require(hasLiked[msg.sender][user], "Have not liked this user");

        hasLiked[msg.sender][user] = false;
        likeCount[user]--;

        emit Unliked(msg.sender, user, block.timestamp);
    }

    /**
     * @dev Get number of likes for an address
     * @param user User address
     * @return Number of likes
     */
    function getLikeCount(address user) public view returns (uint256) {
        return likeCount[user];
    }

    /**
     * @dev Get number of likes for caller
     * @return Number of likes
     */
    function getMyLikeCount() public view returns (uint256) {
        return likeCount[msg.sender];
    }

    /**
     * @dev Check if caller has liked a user
     * @param user User address
     * @return true if liked
     */
    function haveILiked(address user) public view returns (bool) {
        return hasLiked[msg.sender][user];
    }

    /**
     * @dev Check if one user has liked another
     * @param liker Liker address
     * @param liked Liked address
     * @return true if liked
     */
    function hasUserLiked(address liker, address liked) public view returns (bool) {
        return hasLiked[liker][liked];
    }

    /**
     * @dev Get all users who liked a specific address
     * @param user User address
     * @return Array of liker addresses
     */
    function getLikedBy(address user) public view returns (address[] memory) {
        return likedBy[user];
    }

    /**
     * @dev Get all users that a specific address has liked
     * @param user User address
     * @return Array of liked addresses
     */
    function getLikedUsers(address user) public view returns (address[] memory) {
        return likedUsers[user];
    }

    /**
     * @dev Get all users who have received likes
     * @return Array of user addresses
     */
    function getAllUsersWithLikes() public view returns (address[] memory) {
        return usersWithLikes;
    }

    /**
     * @dev Get top liked users
     * @param n Number of top users to return
     * @return addresses Array of addresses
     * @return likes Array of like counts
     */
    function getTopLikedUsers(uint256 n) public view returns (address[] memory addresses, uint256[] memory likes) {
        uint256 userCount = usersWithLikes.length;
        if (n > userCount) {
            n = userCount;
        }

        addresses = new address[](n);
        likes = new uint256[](n);

        // Simple selection sort for top N
        for (uint256 i = 0; i < n; i++) {
            uint256 maxLikes = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == usersWithLikes[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && likeCount[usersWithLikes[j]] > maxLikes) {
                    maxLikes = likeCount[usersWithLikes[j]];
                    maxIndex = j;
                }
            }

            if (maxLikes > 0) {
                addresses[i] = usersWithLikes[maxIndex];
                likes[i] = maxLikes;
            }
        }

        return (addresses, likes);
    }

    /**
     * @dev Get total number of users with likes
     * @return Total count
     */
    function getTotalUsersWithLikes() public view returns (uint256) {
        return usersWithLikes.length;
    }

    /**
     * @dev Get users liked by caller
     * @return Array of liked addresses
     */
    function getMyLikedUsers() public view returns (address[] memory) {
        return likedUsers[msg.sender];
    }

    /**
     * @dev Get users who liked caller
     * @return Array of liker addresses
     */
    function getMyLikers() public view returns (address[] memory) {
        return likedBy[msg.sender];
    }

    /**
     * @dev Get total likes across all users
     * @return Total like count
     */
    function getTotalLikes() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < usersWithLikes.length; i++) {
            total += likeCount[usersWithLikes[i]];
        }
        return total;
    }
}
