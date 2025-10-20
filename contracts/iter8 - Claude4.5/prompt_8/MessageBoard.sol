// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MessageBoard
 * @dev Contract that stores user messages with timestamps, anyone can post and view
 */
contract MessageBoard {
    // Message structure
    struct Message {
        uint256 messageId;
        address author;
        string content;
        uint256 timestamp;
    }

    // State variables
    uint256 private messageIdCounter;
    Message[] private messages;
    mapping(address => uint256[]) private userMessages;
    mapping(address => uint256) private userMessageCount;

    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);

    constructor() {
        messageIdCounter = 0;
    }

    /**
     * @dev Post a new message
     * @param content Message content
     * @return messageId ID of the posted message
     */
    function postMessage(string memory content) public returns (uint256) {
        require(bytes(content).length > 0, "Message content cannot be empty");
        require(bytes(content).length <= 500, "Message too long");

        uint256 messageId = messageIdCounter;
        messageIdCounter++;

        Message memory newMessage = Message({
            messageId: messageId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp
        });

        messages.push(newMessage);
        userMessages[msg.sender].push(messageId);
        userMessageCount[msg.sender]++;

        emit MessagePosted(messageId, msg.sender, content, block.timestamp);

        return messageId;
    }

    /**
     * @dev Get a specific message by ID
     * @param messageId Message ID
     * @return Message details
     */
    function getMessage(uint256 messageId) public view returns (Message memory) {
        require(messageId < messages.length, "Message does not exist");
        return messages[messageId];
    }

    /**
     * @dev Get all messages
     * @return Array of all messages
     */
    function getAllMessages() public view returns (Message[] memory) {
        return messages;
    }

    /**
     * @dev Get messages by author
     * @param author Author address
     * @return Array of messages
     */
    function getMessagesByAuthor(address author) public view returns (Message[] memory) {
        uint256[] memory messageIds = userMessages[author];
        Message[] memory authorMessages = new Message[](messageIds.length);

        for (uint256 i = 0; i < messageIds.length; i++) {
            authorMessages[i] = messages[messageIds[i]];
        }

        return authorMessages;
    }

    /**
     * @dev Get recent messages
     * @param count Number of recent messages to retrieve
     * @return Array of recent messages
     */
    function getRecentMessages(uint256 count) public view returns (Message[] memory) {
        if (count == 0 || messages.length == 0) {
            return new Message[](0);
        }

        if (count > messages.length) {
            count = messages.length;
        }

        Message[] memory recentMessages = new Message[](count);
        uint256 startIndex = messages.length - count;

        for (uint256 i = 0; i < count; i++) {
            recentMessages[i] = messages[startIndex + i];
        }

        return recentMessages;
    }

    /**
     * @dev Get messages in a range
     * @param startIndex Start index
     * @param endIndex End index (inclusive)
     * @return Array of messages
     */
    function getMessagesInRange(uint256 startIndex, uint256 endIndex) public view returns (Message[] memory) {
        require(startIndex <= endIndex, "Invalid range");
        require(endIndex < messages.length, "End index out of bounds");

        uint256 count = endIndex - startIndex + 1;
        Message[] memory rangeMessages = new Message[](count);

        for (uint256 i = 0; i < count; i++) {
            rangeMessages[i] = messages[startIndex + i];
        }

        return rangeMessages;
    }

    /**
     * @dev Get total number of messages
     * @return Total message count
     */
    function getTotalMessages() public view returns (uint256) {
        return messages.length;
    }

    /**
     * @dev Get message count by author
     * @param author Author address
     * @return Message count
     */
    function getMessageCountByAuthor(address author) public view returns (uint256) {
        return userMessageCount[author];
    }

    /**
     * @dev Get caller's messages
     * @return Array of messages
     */
    function getMyMessages() public view returns (Message[] memory) {
        return getMessagesByAuthor(msg.sender);
    }

    /**
     * @dev Get caller's message count
     * @return Message count
     */
    function getMyMessageCount() public view returns (uint256) {
        return userMessageCount[msg.sender];
    }

    /**
     * @dev Get message IDs by author
     * @param author Author address
     * @return Array of message IDs
     */
    function getMessageIdsByAuthor(address author) public view returns (uint256[] memory) {
        return userMessages[author];
    }

    /**
     * @dev Get latest message
     * @return Latest message
     */
    function getLatestMessage() public view returns (Message memory) {
        require(messages.length > 0, "No messages posted yet");
        return messages[messages.length - 1];
    }

    /**
     * @dev Get messages by time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of messages
     */
    function getMessagesByTimeRange(uint256 startTime, uint256 endTime) public view returns (Message[] memory) {
        require(startTime <= endTime, "Invalid time range");

        // Count messages in range
        uint256 count = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (messages[i].timestamp >= startTime && messages[i].timestamp <= endTime) {
                count++;
            }
        }

        // Collect messages
        Message[] memory rangeMessages = new Message[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < messages.length; i++) {
            if (messages[i].timestamp >= startTime && messages[i].timestamp <= endTime) {
                rangeMessages[index] = messages[i];
                index++;
            }
        }

        return rangeMessages;
    }
}
