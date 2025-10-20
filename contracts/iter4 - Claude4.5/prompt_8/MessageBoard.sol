// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MessageBoard
 * @dev A contract that stores user messages with timestamps, allowing anyone to post and view messages
 */
contract MessageBoard {
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
    }
    
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    
    /**
     * @dev Allows anyone to post a message
     * @param _content The content of the message
     */
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message cannot be empty");
        require(bytes(_content).length <= 1000, "Message too long");
        
        messageCount++;
        
        messages[messageCount] = Message({
            id: messageCount,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });
        
        emit MessagePosted(messageCount, msg.sender, _content, block.timestamp);
    }
    
    /**
     * @dev Returns a specific message by ID
     * @param _messageId The ID of the message
     * @return id The message ID
     * @return author The author's address
     * @return content The message content
     * @return timestamp The timestamp when the message was posted
     */
    function getMessage(uint256 _messageId) external view returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp
    ) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        
        Message memory message = messages[_messageId];
        
        return (
            message.id,
            message.author,
            message.content,
            message.timestamp
        );
    }
    
    /**
     * @dev Returns all messages (use with caution for large datasets)
     * @return Array of all messages
     */
    function getAllMessages() external view returns (Message[] memory) {
        Message[] memory allMessages = new Message[](messageCount);
        
        for (uint256 i = 1; i <= messageCount; i++) {
            allMessages[i - 1] = messages[i];
        }
        
        return allMessages;
    }
    
    /**
     * @dev Returns the latest N messages
     * @param _count The number of recent messages to retrieve
     * @return Array of recent messages
     */
    function getRecentMessages(uint256 _count) external view returns (Message[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > messageCount ? messageCount : _count;
        Message[] memory recentMessages = new Message[](count);
        
        uint256 startIndex = messageCount - count + 1;
        
        for (uint256 i = 0; i < count; i++) {
            recentMessages[i] = messages[startIndex + i];
        }
        
        return recentMessages;
    }
    
    /**
     * @dev Returns all messages by a specific author
     * @param _author The address of the author
     * @return Array of messages by the author
     */
    function getMessagesByAuthor(address _author) external view returns (Message[] memory) {
        require(_author != address(0), "Invalid author address");
        
        // First, count messages by author
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == _author) {
                count++;
            }
        }
        
        // Create array and populate it
        Message[] memory authorMessages = new Message[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == _author) {
                authorMessages[index] = messages[i];
                index++;
            }
        }
        
        return authorMessages;
    }
    
    /**
     * @dev Returns the total number of messages posted
     * @return The total message count
     */
    function getTotalMessageCount() external view returns (uint256) {
        return messageCount;
    }
    
    /**
     * @dev Returns messages within a time range
     * @param _startTime The start timestamp
     * @param _endTime The end timestamp
     * @return Array of messages within the time range
     */
    function getMessagesByTimeRange(uint256 _startTime, uint256 _endTime) external view returns (Message[] memory) {
        require(_startTime <= _endTime, "Invalid time range");
        
        // First, count messages in range
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].timestamp >= _startTime && messages[i].timestamp <= _endTime) {
                count++;
            }
        }
        
        // Create array and populate it
        Message[] memory rangeMessages = new Message[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].timestamp >= _startTime && messages[i].timestamp <= _endTime) {
                rangeMessages[index] = messages[i];
                index++;
            }
        }
        
        return rangeMessages;
    }
}
