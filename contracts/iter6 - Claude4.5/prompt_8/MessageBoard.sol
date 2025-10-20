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
        address author;
        string content;
        uint256 timestamp;
    }
    
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    
    /**
     * @dev Post a new message
     * @param content The content of the message
     */
    function postMessage(string memory content) external {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(bytes(content).length <= 1000, "Message too long");
        
        messageCount++;
        
        messages[messageCount] = Message({
            id: messageCount,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp
        });
        
        emit MessagePosted(messageCount, msg.sender, content, block.timestamp);
    }
    
    /**
     * @dev Get a specific message by ID
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
        require(messageId > 0 && messageId <= messageCount, "Message does not exist");
        Message memory message = messages[messageId];
        
        return (
            message.id,
            message.author,
            message.content,
            message.timestamp
        );
    }
    
    /**
     * @dev Get all messages by a specific author
     * @param author The address of the author
     * @return messageIds Array of message IDs posted by the author
     */
    function getMessagesByAuthor(address author) external view returns (uint256[] memory) {
        // First, count messages by author
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == author) {
                count++;
            }
        }
        
        // Create array and populate with message IDs
        uint256[] memory messageIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == author) {
                messageIds[index] = i;
                index++;
            }
        }
        
        return messageIds;
    }
    
    /**
     * @dev Get the latest N messages
     * @param count The number of recent messages to retrieve
     * @return messageIds Array of the latest message IDs
     */
    function getLatestMessages(uint256 count) external view returns (uint256[] memory) {
        if (count > messageCount) {
            count = messageCount;
        }
        
        uint256[] memory messageIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            messageIds[i] = messageCount - i;
        }
        
        return messageIds;
    }
    
    /**
     * @dev Get all message IDs
     * @return messageIds Array of all message IDs
     */
    function getAllMessageIds() external view returns (uint256[] memory) {
        uint256[] memory messageIds = new uint256[](messageCount);
        for (uint256 i = 0; i < messageCount; i++) {
            messageIds[i] = i + 1;
        }
        
        return messageIds;
    }
    
    /**
     * @dev Get multiple messages at once
     * @param messageIds Array of message IDs to retrieve
     * @return authors Array of author addresses
     * @return contents Array of message contents
     * @return timestamps Array of timestamps
     */
    function getMultipleMessages(uint256[] memory messageIds) external view returns (
        address[] memory authors,
        string[] memory contents,
        uint256[] memory timestamps
    ) {
        authors = new address[](messageIds.length);
        contents = new string[](messageIds.length);
        timestamps = new uint256[](messageIds.length);
        
        for (uint256 i = 0; i < messageIds.length; i++) {
            uint256 msgId = messageIds[i];
            if (msgId > 0 && msgId <= messageCount) {
                Message memory message = messages[msgId];
                authors[i] = message.author;
                contents[i] = message.content;
                timestamps[i] = message.timestamp;
            }
        }
        
        return (authors, contents, timestamps);
    }
    
    /**
     * @dev Get the total number of messages posted
     * @return The total message count
     */
    function getTotalMessages() external view returns (uint256) {
        return messageCount;
    }
}
