// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OnChainMessaging
 * @dev A contract that lets users send on-chain messages that can be liked by others
 */
contract OnChainMessaging {
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool isActive;
    }
    
    struct Like {
        address liker;
        uint256 timestamp;
    }
    
    uint256 private messageCounter;
    mapping(uint256 => Message) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(uint256 => Like[]) private messageLikes;
    mapping(address => uint256[]) private userMessages;
    mapping(address => uint256[]) private userLikedMessages;
    
    event MessagePosted(
        uint256 indexed messageId,
        address indexed author,
        string content,
        uint256 timestamp
    );
    
    event MessageLiked(
        uint256 indexed messageId,
        address indexed liker,
        uint256 totalLikes,
        uint256 timestamp
    );
    
    event MessageUnliked(
        uint256 indexed messageId,
        address indexed liker,
        uint256 totalLikes,
        uint256 timestamp
    );
    
    event MessageDeleted(
        uint256 indexed messageId,
        address indexed author,
        uint256 timestamp
    );
    
    modifier messageExists(uint256 messageId) {
        require(messageId > 0 && messageId <= messageCounter, "Message does not exist");
        require(messages[messageId].isActive, "Message has been deleted");
        _;
    }
    
    modifier onlyAuthor(uint256 messageId) {
        require(messages[messageId].author == msg.sender, "Only author can perform this action");
        _;
    }
    
    /**
     * @dev Post a new message
     * @param content The message content
     * @return messageId The ID of the posted message
     */
    function postMessage(string memory content) external returns (uint256) {
        require(bytes(content).length > 0, "Message content cannot be empty");
        require(bytes(content).length <= 1000, "Message content too long");
        
        messageCounter++;
        uint256 messageId = messageCounter;
        
        messages[messageId] = Message({
            id: messageId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp,
            likes: 0,
            isActive: true
        });
        
        userMessages[msg.sender].push(messageId);
        
        emit MessagePosted(messageId, msg.sender, content, block.timestamp);
        
        return messageId;
    }
    
    /**
     * @dev Like a message
     * @param messageId The ID of the message to like
     */
    function likeMessage(uint256 messageId) external messageExists(messageId) {
        require(!hasLiked[messageId][msg.sender], "Already liked this message");
        require(messages[messageId].author != msg.sender, "Cannot like own message");
        
        hasLiked[messageId][msg.sender] = true;
        messages[messageId].likes++;
        
        Like memory newLike = Like({
            liker: msg.sender,
            timestamp: block.timestamp
        });
        
        messageLikes[messageId].push(newLike);
        userLikedMessages[msg.sender].push(messageId);
        
        emit MessageLiked(messageId, msg.sender, messages[messageId].likes, block.timestamp);
    }
    
    /**
     * @dev Unlike a message
     * @param messageId The ID of the message to unlike
     */
    function unlikeMessage(uint256 messageId) external messageExists(messageId) {
        require(hasLiked[messageId][msg.sender], "Haven't liked this message");
        
        hasLiked[messageId][msg.sender] = false;
        messages[messageId].likes--;
        
        // Remove from messageLikes array
        Like[] storage likes = messageLikes[messageId];
        for (uint256 i = 0; i < likes.length; i++) {
            if (likes[i].liker == msg.sender) {
                likes[i] = likes[likes.length - 1];
                likes.pop();
                break;
            }
        }
        
        // Remove from userLikedMessages array
        uint256[] storage likedMessages = userLikedMessages[msg.sender];
        for (uint256 i = 0; i < likedMessages.length; i++) {
            if (likedMessages[i] == messageId) {
                likedMessages[i] = likedMessages[likedMessages.length - 1];
                likedMessages.pop();
                break;
            }
        }
        
        emit MessageUnliked(messageId, msg.sender, messages[messageId].likes, block.timestamp);
    }
    
    /**
     * @dev Delete a message (only by author)
     * @param messageId The ID of the message to delete
     */
    function deleteMessage(uint256 messageId) 
        external 
        messageExists(messageId) 
        onlyAuthor(messageId) 
    {
        messages[messageId].isActive = false;
        
        emit MessageDeleted(messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get message details
     * @param messageId The ID of the message
     * @return id Message ID
     * @return author Author address
     * @return content Message content
     * @return timestamp When the message was posted
     * @return likes Number of likes
     * @return isActive Whether the message is active
     */
    function getMessage(uint256 messageId) 
        external 
        view 
        messageExists(messageId) 
        returns (
            uint256 id,
            address author,
            string memory content,
            uint256 timestamp,
            uint256 likes,
            bool isActive
        ) 
    {
        Message memory message = messages[messageId];
        return (
            message.id,
            message.author,
            message.content,
            message.timestamp,
            message.likes,
            message.isActive
        );
    }
    
    /**
     * @dev Get all likes for a message
     * @param messageId The ID of the message
     * @return Array of likes
     */
    function getMessageLikes(uint256 messageId) 
        external 
        view 
        messageExists(messageId) 
        returns (Like[] memory) 
    {
        return messageLikes[messageId];
    }
    
    /**
     * @dev Get messages posted by a user
     * @param user The user's address
     * @return Array of message IDs
     */
    function getMessagesByUser(address user) external view returns (uint256[] memory) {
        return userMessages[user];
    }
    
    /**
     * @dev Get active messages posted by a user
     * @param user The user's address
     * @return Array of active message IDs
     */
    function getActiveMessagesByUser(address user) external view returns (uint256[] memory) {
        uint256[] memory allMessages = userMessages[user];
        uint256 activeCount = 0;
        
        // Count active messages
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].isActive) {
                activeCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeMessages = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].isActive) {
                activeMessages[index] = allMessages[i];
                index++;
            }
        }
        
        return activeMessages;
    }
    
    /**
     * @dev Get messages liked by a user
     * @param user The user's address
     * @return Array of message IDs
     */
    function getLikedMessagesByUser(address user) external view returns (uint256[] memory) {
        return userLikedMessages[user];
    }
    
    /**
     * @dev Get all messages
     * @return Array of all message IDs
     */
    function getAllMessages() external view returns (uint256[] memory) {
        uint256[] memory allMessages = new uint256[](messageCounter);
        
        for (uint256 i = 1; i <= messageCounter; i++) {
            allMessages[i - 1] = i;
        }
        
        return allMessages;
    }
    
    /**
     * @dev Get all active messages
     * @return Array of active message IDs
     */
    function getAllActiveMessages() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active messages
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory activeMessages = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].isActive) {
                activeMessages[index] = i;
                index++;
            }
        }
        
        return activeMessages;
    }
    
    /**
     * @dev Get most liked messages (top N)
     * @param count Number of top messages to return
     * @return Array of message IDs sorted by likes
     */
    function getMostLikedMessages(uint256 count) external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active messages
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        if (activeCount == 0) {
            return new uint256[](0);
        }
        
        // Get all active message IDs
        uint256[] memory activeMessageIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].isActive) {
                activeMessageIds[index] = i;
                index++;
            }
        }
        
        // Simple bubble sort (descending by likes)
        for (uint256 i = 0; i < activeMessageIds.length; i++) {
            for (uint256 j = i + 1; j < activeMessageIds.length; j++) {
                if (messages[activeMessageIds[i]].likes < messages[activeMessageIds[j]].likes) {
                    uint256 temp = activeMessageIds[i];
                    activeMessageIds[i] = activeMessageIds[j];
                    activeMessageIds[j] = temp;
                }
            }
        }
        
        // Return top N
        uint256 resultCount = count > activeMessageIds.length ? activeMessageIds.length : count;
        uint256[] memory result = new uint256[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = activeMessageIds[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get recent messages (last N)
     * @param count Number of recent messages to return
     * @return Array of message IDs
     */
    function getRecentMessages(uint256 count) external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active messages
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        if (activeCount == 0) {
            return new uint256[](0);
        }
        
        uint256 resultCount = count > activeCount ? activeCount : count;
        uint256[] memory result = new uint256[](resultCount);
        uint256 index = 0;
        
        // Get most recent active messages (iterate backwards)
        for (uint256 i = messageCounter; i >= 1 && index < resultCount; i--) {
            if (messages[i].isActive) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Check if a user has liked a message
     * @param messageId The ID of the message
     * @param user The user's address
     * @return Whether the user has liked the message
     */
    function hasUserLiked(uint256 messageId, address user) 
        external 
        view 
        messageExists(messageId) 
        returns (bool) 
    {
        return hasLiked[messageId][user];
    }
    
    /**
     * @dev Get like count for a message
     * @param messageId The ID of the message
     * @return The number of likes
     */
    function getLikeCount(uint256 messageId) 
        external 
        view 
        messageExists(messageId) 
        returns (uint256) 
    {
        return messages[messageId].likes;
    }
    
    /**
     * @dev Get total number of messages
     * @return The total count
     */
    function getTotalMessages() external view returns (uint256) {
        return messageCounter;
    }
    
    /**
     * @dev Get total number of active messages
     * @return The count of active messages
     */
    function getTotalActiveMessages() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Get message count by user
     * @param user The user's address
     * @return The number of messages posted
     */
    function getMessageCountByUser(address user) external view returns (uint256) {
        return userMessages[user].length;
    }
    
    /**
     * @dev Get active message count by user
     * @param user The user's address
     * @return The number of active messages posted
     */
    function getActiveMessageCountByUser(address user) external view returns (uint256) {
        uint256[] memory allMessages = userMessages[user];
        uint256 count = 0;
        
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Get total likes received by a user across all their messages
     * @param user The user's address
     * @return Total likes received
     */
    function getTotalLikesReceivedByUser(address user) external view returns (uint256) {
        uint256[] memory userMessageList = userMessages[user];
        uint256 totalLikes = 0;
        
        for (uint256 i = 0; i < userMessageList.length; i++) {
            if (messages[userMessageList[i]].isActive) {
                totalLikes += messages[userMessageList[i]].likes;
            }
        }
        
        return totalLikes;
    }
    
    /**
     * @dev Check if a message is active
     * @param messageId The ID of the message
     * @return Whether the message is active
     */
    function isMessageActive(uint256 messageId) external view returns (bool) {
        if (messageId == 0 || messageId > messageCounter) {
            return false;
        }
        return messages[messageId].isActive;
    }
}
