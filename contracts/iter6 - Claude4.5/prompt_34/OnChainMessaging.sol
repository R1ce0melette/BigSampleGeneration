// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OnChainMessaging
 * @dev A contract that lets users send on-chain messages that can be liked by others
 */
contract OnChainMessaging {
    struct Message {
        uint256 messageId;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool exists;
    }
    
    struct UserProfile {
        uint256 messagesSent;
        uint256 totalLikesReceived;
        uint256 totalLikesGiven;
    }
    
    uint256 public messageCount;
    
    mapping(uint256 => Message) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(uint256 => address[]) public messageLikers;
    mapping(address => uint256[]) public userMessages;
    mapping(address => UserProfile) public userProfiles;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 timestamp);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 timestamp);
    event MessageDeleted(uint256 indexed messageId, address indexed sender, uint256 timestamp);
    
    modifier messageExists(uint256 messageId) {
        require(messageId > 0 && messageId <= messageCount, "Message does not exist");
        require(messages[messageId].exists, "Message does not exist");
        _;
    }
    
    modifier onlyMessageSender(uint256 messageId) {
        require(messages[messageId].sender == msg.sender, "Only message sender can perform this action");
        _;
    }
    
    /**
     * @dev Post a new message
     * @param content The message content
     */
    function postMessage(string memory content) external returns (uint256) {
        require(bytes(content).length > 0, "Message content cannot be empty");
        require(bytes(content).length <= 1000, "Message content too long");
        
        messageCount++;
        uint256 messageId = messageCount;
        
        messages[messageId] = Message({
            messageId: messageId,
            sender: msg.sender,
            content: content,
            timestamp: block.timestamp,
            likes: 0,
            exists: true
        });
        
        userMessages[msg.sender].push(messageId);
        userProfiles[msg.sender].messagesSent++;
        
        emit MessagePosted(messageId, msg.sender, content, block.timestamp);
        
        return messageId;
    }
    
    /**
     * @dev Like a message
     * @param messageId The message ID to like
     */
    function likeMessage(uint256 messageId) external messageExists(messageId) {
        require(!hasLiked[messageId][msg.sender], "Already liked this message");
        require(messages[messageId].sender != msg.sender, "Cannot like your own message");
        
        hasLiked[messageId][msg.sender] = true;
        messages[messageId].likes++;
        messageLikers[messageId].push(msg.sender);
        
        userProfiles[messages[messageId].sender].totalLikesReceived++;
        userProfiles[msg.sender].totalLikesGiven++;
        
        emit MessageLiked(messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Unlike a message
     * @param messageId The message ID to unlike
     */
    function unlikeMessage(uint256 messageId) external messageExists(messageId) {
        require(hasLiked[messageId][msg.sender], "Have not liked this message");
        
        hasLiked[messageId][msg.sender] = false;
        messages[messageId].likes--;
        
        userProfiles[messages[messageId].sender].totalLikesReceived--;
        userProfiles[msg.sender].totalLikesGiven--;
        
        emit MessageUnliked(messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Delete a message (only sender can delete)
     * @param messageId The message ID to delete
     */
    function deleteMessage(uint256 messageId) external messageExists(messageId) onlyMessageSender(messageId) {
        messages[messageId].exists = false;
        
        emit MessageDeleted(messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get message details
     * @param messageId The message ID
     * @return sender Sender address
     * @return content Message content
     * @return timestamp Creation timestamp
     * @return likes Number of likes
     */
    function getMessage(uint256 messageId) external view messageExists(messageId) returns (
        address sender,
        string memory content,
        uint256 timestamp,
        uint256 likes
    ) {
        Message memory message = messages[messageId];
        
        return (
            message.sender,
            message.content,
            message.timestamp,
            message.likes
        );
    }
    
    /**
     * @dev Get all messages by a user
     * @param user The user address
     * @return Array of message IDs
     */
    function getUserMessages(address user) external view returns (uint256[] memory) {
        return userMessages[user];
    }
    
    /**
     * @dev Get user profile
     * @param user The user address
     * @return messagesSent Number of messages sent
     * @return totalLikesReceived Total likes received on messages
     * @return totalLikesGiven Total likes given to others
     */
    function getUserProfile(address user) external view returns (
        uint256 messagesSent,
        uint256 totalLikesReceived,
        uint256 totalLikesGiven
    ) {
        UserProfile memory profile = userProfiles[user];
        
        return (
            profile.messagesSent,
            profile.totalLikesReceived,
            profile.totalLikesGiven
        );
    }
    
    /**
     * @dev Get all users who liked a message
     * @param messageId The message ID
     * @return Array of liker addresses
     */
    function getMessageLikers(uint256 messageId) external view messageExists(messageId) returns (address[] memory) {
        return messageLikers[messageId];
    }
    
    /**
     * @dev Check if user has liked a message
     * @param messageId The message ID
     * @param user The user address
     * @return True if user has liked the message
     */
    function hasUserLiked(uint256 messageId, address user) external view messageExists(messageId) returns (bool) {
        return hasLiked[messageId][user];
    }
    
    /**
     * @dev Get recent messages
     * @param count Number of recent messages to retrieve
     * @return Array of message IDs
     */
    function getRecentMessages(uint256 count) external view returns (uint256[] memory) {
        if (count > messageCount) {
            count = messageCount;
        }
        
        uint256[] memory recentMessages = new uint256[](count);
        uint256 index = 0;
        
        // Get most recent messages (working backwards from messageCount)
        for (uint256 i = messageCount; i > 0 && index < count; i--) {
            if (messages[i].exists) {
                recentMessages[index] = i;
                index++;
            }
        }
        
        // If we didn't fill the array, resize it
        if (index < count) {
            uint256[] memory resized = new uint256[](index);
            for (uint256 i = 0; i < index; i++) {
                resized[i] = recentMessages[i];
            }
            return resized;
        }
        
        return recentMessages;
    }
    
    /**
     * @dev Get most liked messages
     * @param count Number of top messages to retrieve
     * @return Array of message IDs sorted by likes
     */
    function getMostLikedMessages(uint256 count) external view returns (uint256[] memory) {
        if (count > messageCount) {
            count = messageCount;
        }
        
        uint256[] memory topMessages = new uint256[](count);
        uint256[] memory topLikes = new uint256[](count);
        
        // Find top messages
        for (uint256 i = 1; i <= messageCount; i++) {
            if (!messages[i].exists) continue;
            
            uint256 likes = messages[i].likes;
            
            // Check if this message belongs in top
            for (uint256 j = 0; j < count; j++) {
                if (topMessages[j] == 0 || likes > topLikes[j]) {
                    // Shift down lower messages
                    for (uint256 k = count - 1; k > j; k--) {
                        topMessages[k] = topMessages[k - 1];
                        topLikes[k] = topLikes[k - 1];
                    }
                    // Insert new top message
                    topMessages[j] = i;
                    topLikes[j] = likes;
                    break;
                }
            }
        }
        
        // Count actual messages found
        uint256 actualCount = 0;
        for (uint256 i = 0; i < count; i++) {
            if (topMessages[i] != 0) {
                actualCount++;
            }
        }
        
        // Resize if needed
        if (actualCount < count) {
            uint256[] memory resized = new uint256[](actualCount);
            for (uint256 i = 0; i < actualCount; i++) {
                resized[i] = topMessages[i];
            }
            return resized;
        }
        
        return topMessages;
    }
    
    /**
     * @dev Get messages liked by a user
     * @param user The user address
     * @return Array of message IDs
     */
    function getMessagesLikedByUser(address user) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count liked messages
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].exists && hasLiked[i][user]) {
                count++;
            }
        }
        
        // Collect message IDs
        uint256[] memory likedMessages = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].exists && hasLiked[i][user]) {
                likedMessages[index] = i;
                index++;
            }
        }
        
        return likedMessages;
    }
    
    /**
     * @dev Get total number of messages
     * @return Total message count
     */
    function getTotalMessages() external view returns (uint256) {
        return messageCount;
    }
    
    /**
     * @dev Get active message count (non-deleted)
     * @return Active message count
     */
    function getActiveMessageCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].exists) {
                count++;
            }
        }
        return count;
    }
    
    /**
     * @dev Check if message exists
     * @param messageId The message ID
     * @return True if message exists
     */
    function messageExistsCheck(uint256 messageId) external view returns (bool) {
        return messageId > 0 && messageId <= messageCount && messages[messageId].exists;
    }
    
    /**
     * @dev Get message like count
     * @param messageId The message ID
     * @return Number of likes
     */
    function getMessageLikes(uint256 messageId) external view messageExists(messageId) returns (uint256) {
        return messages[messageId].likes;
    }
    
    /**
     * @dev Get messages by sender
     * @param sender The sender address
     * @return Array of message IDs
     */
    function getMessagesBySender(address sender) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count messages by sender that still exist
        for (uint256 i = 0; i < userMessages[sender].length; i++) {
            if (messages[userMessages[sender][i]].exists) {
                count++;
            }
        }
        
        // Collect active message IDs
        uint256[] memory activeMessages = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < userMessages[sender].length; i++) {
            uint256 msgId = userMessages[sender][i];
            if (messages[msgId].exists) {
                activeMessages[index] = msgId;
                index++;
            }
        }
        
        return activeMessages;
    }
    
    /**
     * @dev Get all messages (paginated)
     * @param offset Starting index
     * @param limit Number of messages to return
     * @return Array of message IDs
     */
    function getAllMessages(uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        require(offset < messageCount, "Offset out of bounds");
        
        uint256 end = offset + limit;
        if (end > messageCount) {
            end = messageCount;
        }
        
        uint256 count = 0;
        for (uint256 i = offset + 1; i <= end; i++) {
            if (messages[i].exists) {
                count++;
            }
        }
        
        uint256[] memory messageIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = offset + 1; i <= end; i++) {
            if (messages[i].exists) {
                messageIds[index] = i;
                index++;
            }
        }
        
        return messageIds;
    }
}
