// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MessageBoard
 * @dev A contract that stores user messages with timestamps
 * Anyone can post and view messages
 */
contract MessageBoard {
    // Message structure
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
    }
    
    // State variables
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    
    /**
     * @dev Post a new message
     * @param content The content of the message
     * @return messageId The ID of the posted message
     */
    function postMessage(string memory content) external returns (uint256) {
        require(bytes(content).length > 0, "Message content cannot be empty");
        require(bytes(content).length <= 1000, "Message content too long");
        
        messageCount++;
        uint256 messageId = messageCount;
        
        messages[messageId] = Message({
            id: messageId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp
        });
        
        emit MessagePosted(messageId, msg.sender, content, block.timestamp);
        
        return messageId;
    }
    
    /**
     * @dev Get a specific message
     * @param messageId The ID of the message
     * @return id The message ID
     * @return author The author's address
     * @return content The message content
     * @return timestamp The timestamp when the message was posted
     */
    function getMessage(uint256 messageId) external view returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp
    ) {
        require(messageId > 0 && messageId <= messageCount, "Invalid message ID");
        
        Message memory message = messages[messageId];
        return (
            message.id,
            message.author,
            message.content,
            message.timestamp
        );
    }
    
    /**
     * @dev Get all messages
     * Note: This function may be gas-intensive for large datasets
     * @return allMessages Array of all messages
     */
    function getAllMessages() external view returns (Message[] memory) {
        Message[] memory allMessages = new Message[](messageCount);
        
        for (uint256 i = 1; i <= messageCount; i++) {
            allMessages[i - 1] = messages[i];
        }
        
        return allMessages;
    }
    
    /**
     * @dev Get messages in a specific range
     * @param startId The starting message ID (inclusive)
     * @param endId The ending message ID (inclusive)
     * @return rangeMessages Array of messages in the specified range
     */
    function getMessageRange(uint256 startId, uint256 endId) external view returns (Message[] memory) {
        require(startId > 0 && startId <= messageCount, "Invalid start ID");
        require(endId > 0 && endId <= messageCount, "Invalid end ID");
        require(startId <= endId, "Start ID must be less than or equal to end ID");
        
        uint256 rangeSize = endId - startId + 1;
        Message[] memory rangeMessages = new Message[](rangeSize);
        
        for (uint256 i = 0; i < rangeSize; i++) {
            rangeMessages[i] = messages[startId + i];
        }
        
        return rangeMessages;
    }
    
    /**
     * @dev Get the latest N messages
     * @param count The number of latest messages to retrieve
     * @return latestMessages Array of the latest messages
     */
    function getLatestMessages(uint256 count) external view returns (Message[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 actualCount = count > messageCount ? messageCount : count;
        Message[] memory latestMessages = new Message[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            latestMessages[i] = messages[messageCount - i];
        }
        
        return latestMessages;
    }
    
    /**
     * @dev Get messages by a specific author
     * Note: This function may be gas-intensive for large datasets
     * @param author The address of the author
     * @return authorMessages Array of messages by the specified author
     */
    function getMessagesByAuthor(address author) external view returns (Message[] memory) {
        require(author != address(0), "Invalid author address");
        
        // Count messages by author
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == author) {
                count++;
            }
        }
        
        // Create array of author's messages
        Message[] memory authorMessages = new Message[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == author) {
                authorMessages[index] = messages[i];
                index++;
            }
        }
        
        return authorMessages;
    }
    
    /**
     * @dev Get the total number of messages
     * @return The total message count
     */
    function getTotalMessages() external view returns (uint256) {
        return messageCount;
    }
}
