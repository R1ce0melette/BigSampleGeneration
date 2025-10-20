// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MessageBoard
 * @dev A contract that stores user messages with timestamps
 * Anyone can post and view messages
 */
contract MessageBoard {
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
    }
    
    Message[] public messages;
    mapping(address => uint256[]) private userMessageIds;
    
    event MessagePosted(
        uint256 indexed messageId,
        address indexed sender,
        string content,
        uint256 timestamp
    );
    
    /**
     * @dev Post a new message
     * @param content The content of the message
     * @return messageId The ID of the posted message
     */
    function postMessage(string memory content) external returns (uint256) {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(bytes(content).length <= 1000, "Message too long");
        
        uint256 messageId = messages.length;
        
        Message memory newMessage = Message({
            id: messageId,
            sender: msg.sender,
            content: content,
            timestamp: block.timestamp
        });
        
        messages.push(newMessage);
        userMessageIds[msg.sender].push(messageId);
        
        emit MessagePosted(messageId, msg.sender, content, block.timestamp);
        
        return messageId;
    }
    
    /**
     * @dev Get a specific message by ID
     * @param messageId The ID of the message
     * @return id Message ID
     * @return sender Address of the sender
     * @return content Message content
     * @return timestamp When the message was posted
     */
    function getMessage(uint256 messageId) external view returns (
        uint256 id,
        address sender,
        string memory content,
        uint256 timestamp
    ) {
        require(messageId < messages.length, "Message does not exist");
        
        Message memory message = messages[messageId];
        
        return (
            message.id,
            message.sender,
            message.content,
            message.timestamp
        );
    }
    
    /**
     * @dev Get all messages
     * @return Array of all messages
     */
    function getAllMessages() external view returns (Message[] memory) {
        return messages;
    }
    
    /**
     * @dev Get the total number of messages
     * @return The total count of messages
     */
    function getMessageCount() external view returns (uint256) {
        return messages.length;
    }
    
    /**
     * @dev Get all message IDs posted by a specific user
     * @param user The address of the user
     * @return Array of message IDs
     */
    function getMessageIdsByUser(address user) external view returns (uint256[] memory) {
        return userMessageIds[user];
    }
    
    /**
     * @dev Get all messages posted by a specific user
     * @param user The address of the user
     * @return Array of messages posted by the user
     */
    function getMessagesByUser(address user) external view returns (Message[] memory) {
        uint256[] memory messageIds = userMessageIds[user];
        Message[] memory userMessages = new Message[](messageIds.length);
        
        for (uint256 i = 0; i < messageIds.length; i++) {
            userMessages[i] = messages[messageIds[i]];
        }
        
        return userMessages;
    }
    
    /**
     * @dev Get the latest N messages
     * @param count Number of messages to retrieve
     * @return Array of the latest messages
     */
    function getLatestMessages(uint256 count) external view returns (Message[] memory) {
        if (count > messages.length) {
            count = messages.length;
        }
        
        Message[] memory latestMessages = new Message[](count);
        uint256 startIndex = messages.length - count;
        
        for (uint256 i = 0; i < count; i++) {
            latestMessages[i] = messages[startIndex + i];
        }
        
        return latestMessages;
    }
    
    /**
     * @dev Get messages within a specific time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of messages within the time range
     */
    function getMessagesByTimeRange(uint256 startTime, uint256 endTime) external view returns (Message[] memory) {
        require(startTime <= endTime, "Invalid time range");
        
        // First count matching messages
        uint256 count = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (messages[i].timestamp >= startTime && messages[i].timestamp <= endTime) {
                count++;
            }
        }
        
        // Create array and populate
        Message[] memory filteredMessages = new Message[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < messages.length; i++) {
            if (messages[i].timestamp >= startTime && messages[i].timestamp <= endTime) {
                filteredMessages[index] = messages[i];
                index++;
            }
        }
        
        return filteredMessages;
    }
    
    /**
     * @dev Get the number of messages posted by a user
     * @param user The address of the user
     * @return The count of messages posted by the user
     */
    function getUserMessageCount(address user) external view returns (uint256) {
        return userMessageIds[user].length;
    }
}
