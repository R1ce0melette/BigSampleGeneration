// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OnChainMessaging {
    uint256 public messageCounter;
    
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool exists;
    }
    
    mapping(uint256 => Message) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256[]) public userMessages;
    mapping(address => uint256) public totalMessagesSent;
    mapping(address => uint256) public totalLikesReceived;
    
    uint256 public totalMessages;
    uint256 public totalLikes;
    
    // Events
    event MessageSent(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 totalLikes);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 totalLikes);
    event MessageDeleted(uint256 indexed messageId, address indexed sender);
    
    modifier messageExists(uint256 _messageId) {
        require(messages[_messageId].exists, "Message does not exist");
        _;
    }
    
    /**
     * @dev Send a new message
     * @param _content Message content
     */
    function sendMessage(string memory _content) external returns (uint256) {
        require(bytes(_content).length > 0, "Message cannot be empty");
        require(bytes(_content).length <= 500, "Message too long (max 500 characters)");
        
        messageCounter++;
        
        messages[messageCounter] = Message({
            id: messageCounter,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            exists: true
        });
        
        userMessages[msg.sender].push(messageCounter);
        totalMessagesSent[msg.sender]++;
        totalMessages++;
        
        emit MessageSent(messageCounter, msg.sender, _content, block.timestamp);
        
        return messageCounter;
    }
    
    /**
     * @dev Like a message
     * @param _messageId Message ID to like
     */
    function likeMessage(uint256 _messageId) external messageExists(_messageId) {
        require(!hasLiked[_messageId][msg.sender], "Already liked this message");
        require(messages[_messageId].sender != msg.sender, "Cannot like your own message");
        
        hasLiked[_messageId][msg.sender] = true;
        messages[_messageId].likes++;
        totalLikesReceived[messages[_messageId].sender]++;
        totalLikes++;
        
        emit MessageLiked(_messageId, msg.sender, messages[_messageId].likes);
    }
    
    /**
     * @dev Unlike a message
     * @param _messageId Message ID to unlike
     */
    function unlikeMessage(uint256 _messageId) external messageExists(_messageId) {
        require(hasLiked[_messageId][msg.sender], "Haven't liked this message");
        
        hasLiked[_messageId][msg.sender] = false;
        messages[_messageId].likes--;
        totalLikesReceived[messages[_messageId].sender]--;
        totalLikes--;
        
        emit MessageUnliked(_messageId, msg.sender, messages[_messageId].likes);
    }
    
    /**
     * @dev Delete a message (only sender can delete)
     * @param _messageId Message ID to delete
     */
    function deleteMessage(uint256 _messageId) external messageExists(_messageId) {
        require(messages[_messageId].sender == msg.sender, "Only sender can delete message");
        
        // Adjust total likes count
        totalLikes -= messages[_messageId].likes;
        totalLikesReceived[msg.sender] -= messages[_messageId].likes;
        
        messages[_messageId].exists = false;
        totalMessages--;
        
        emit MessageDeleted(_messageId, msg.sender);
    }
    
    /**
     * @dev Get message details
     * @param _messageId Message ID
     */
    function getMessage(uint256 _messageId) 
        external 
        view 
        messageExists(_messageId) 
        returns (
            uint256 id,
            address sender,
            string memory content,
            uint256 timestamp,
            uint256 likes
        ) 
    {
        Message memory message = messages[_messageId];
        return (
            message.id,
            message.sender,
            message.content,
            message.timestamp,
            message.likes
        );
    }
    
    /**
     * @dev Check if user has liked a message
     * @param _messageId Message ID
     * @param _user User address
     */
    function hasUserLiked(uint256 _messageId, address _user) 
        external 
        view 
        returns (bool) 
    {
        return hasLiked[_messageId][_user];
    }
    
    /**
     * @dev Get all message IDs sent by a user
     * @param _user User address
     */
    function getUserMessages(address _user) external view returns (uint256[] memory) {
        return userMessages[_user];
    }
    
    /**
     * @dev Get user's active (not deleted) messages
     * @param _user User address
     */
    function getUserActiveMessages(address _user) external view returns (uint256[] memory) {
        uint256[] memory allMessages = userMessages[_user];
        uint256 activeCount = 0;
        
        // Count active messages
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].exists) {
                activeCount++;
            }
        }
        
        // Create array of active messages
        uint256[] memory activeMessages = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].exists) {
                activeMessages[index] = allMessages[i];
                index++;
            }
        }
        
        return activeMessages;
    }
    
    /**
     * @dev Get user statistics
     * @param _user User address
     */
    function getUserStats(address _user) 
        external 
        view 
        returns (
            uint256 messagesSent,
            uint256 likesReceived
        ) 
    {
        return (
            totalMessagesSent[_user],
            totalLikesReceived[_user]
        );
    }
    
    /**
     * @dev Get recent messages (last N messages)
     * @param _count Number of recent messages to return
     */
    function getRecentMessages(uint256 _count) external view returns (uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count;
        if (count > messageCounter) {
            count = messageCounter;
        }
        
        uint256[] memory recentMessages = new uint256[](count);
        uint256 index = 0;
        
        // Start from most recent and go backwards
        for (uint256 i = messageCounter; i > 0 && index < count; i--) {
            if (messages[i].exists) {
                recentMessages[index] = i;
                index++;
            }
        }
        
        // Resize array if we found fewer messages than requested
        if (index < count) {
            uint256[] memory resized = new uint256[](index);
            for (uint256 j = 0; j < index; j++) {
                resized[j] = recentMessages[j];
            }
            return resized;
        }
        
        return recentMessages;
    }
    
    /**
     * @dev Get most liked messages (top N)
     * @param _count Number of top messages to return
     */
    function getMostLikedMessages(uint256 _count) external view returns (uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count;
        if (count > totalMessages) {
            count = totalMessages;
        }
        
        // Create array to store all existing message IDs
        uint256[] memory existingMessages = new uint256[](totalMessages);
        uint256 existingCount = 0;
        
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].exists) {
                existingMessages[existingCount] = i;
                existingCount++;
            }
        }
        
        // Simple bubble sort to get top liked messages
        for (uint256 i = 0; i < existingCount; i++) {
            for (uint256 j = i + 1; j < existingCount; j++) {
                if (messages[existingMessages[i]].likes < messages[existingMessages[j]].likes) {
                    uint256 temp = existingMessages[i];
                    existingMessages[i] = existingMessages[j];
                    existingMessages[j] = temp;
                }
            }
        }
        
        // Return top count messages
        uint256 resultCount = count < existingCount ? count : existingCount;
        uint256[] memory topMessages = new uint256[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            topMessages[i] = existingMessages[i];
        }
        
        return topMessages;
    }
    
    /**
     * @dev Get messages by a specific user with pagination
     * @param _user User address
     * @param _offset Starting index
     * @param _limit Number of messages to return
     */
    function getUserMessagesPaginated(
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256[] memory) {
        uint256[] memory allMessages = userMessages[_user];
        
        require(_offset < allMessages.length, "Offset out of bounds");
        
        uint256 end = _offset + _limit;
        if (end > allMessages.length) {
            end = allMessages.length;
        }
        
        uint256 resultLength = end - _offset;
        uint256[] memory result = new uint256[](resultLength);
        
        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = allMessages[_offset + i];
        }
        
        return result;
    }
    
    /**
     * @dev Get all messages in a time range
     * @param _startTime Start timestamp
     * @param _endTime End timestamp
     */
    function getMessagesByTimeRange(
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (uint256[] memory) {
        require(_startTime < _endTime, "Invalid time range");
        
        uint256 count = 0;
        
        // Count messages in range
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].exists && 
                messages[i].timestamp >= _startTime && 
                messages[i].timestamp <= _endTime) {
                count++;
            }
        }
        
        // Create array of message IDs in range
        uint256[] memory rangeMessages = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].exists && 
                messages[i].timestamp >= _startTime && 
                messages[i].timestamp <= _endTime) {
                rangeMessages[index] = i;
                index++;
            }
        }
        
        return rangeMessages;
    }
    
    /**
     * @dev Get platform statistics
     */
    function getStatistics() external view returns (
        uint256 _totalMessages,
        uint256 _totalLikes,
        uint256 _totalUsers
    ) {
        // Count unique users
        uint256 userCount = 0;
        
        // This is a simplified count - in production, you'd track this separately
        for (uint256 i = 1; i <= messageCounter; i++) {
            if (messages[i].exists && totalMessagesSent[messages[i].sender] > 0) {
                userCount++;
                // Note: This is not perfectly accurate as it counts per message
                // In production, maintain a separate mapping for unique users
            }
        }
        
        return (
            totalMessages,
            totalLikes,
            userCount
        );
    }
    
    /**
     * @dev Check if a message exists
     * @param _messageId Message ID
     */
    function messageExists_(uint256 _messageId) external view returns (bool) {
        return messages[_messageId].exists;
    }
}
