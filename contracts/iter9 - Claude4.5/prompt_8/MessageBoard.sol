// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
    }
    
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    
    /**
     * @dev Post a new message
     * @param _content The content of the message
     */
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message cannot be empty");
        require(bytes(_content).length <= 1000, "Message too long");
        
        messageCount++;
        
        messages[messageCount] = Message({
            id: messageCount,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });
        
        emit MessagePosted(messageCount, msg.sender, _content, block.timestamp);
    }
    
    /**
     * @dev Get a specific message
     * @param _messageId The ID of the message
     * @return id The message ID
     * @return sender The sender address
     * @return content The message content
     * @return timestamp The timestamp when the message was posted
     */
    function getMessage(uint256 _messageId) external view returns (
        uint256 id,
        address sender,
        string memory content,
        uint256 timestamp
    ) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        
        Message memory message = messages[_messageId];
        
        return (
            message.id,
            message.sender,
            message.content,
            message.timestamp
        );
    }
    
    /**
     * @dev Get recent messages (up to a specified limit)
     * @param _limit The maximum number of messages to return
     * @return An array of message IDs in reverse chronological order
     */
    function getRecentMessages(uint256 _limit) external view returns (uint256[] memory) {
        uint256 count = messageCount < _limit ? messageCount : _limit;
        uint256[] memory recentMessageIds = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentMessageIds[i] = messageCount - i;
        }
        
        return recentMessageIds;
    }
    
    /**
     * @dev Get messages by a specific sender
     * @param _sender The address of the sender
     * @param _limit Maximum number of messages to return
     * @return An array of message IDs from the sender
     */
    function getMessagesBySender(address _sender, uint256 _limit) external view returns (uint256[] memory) {
        // First, count messages from sender
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount && count < _limit; i++) {
            if (messages[i].sender == _sender) {
                count++;
            }
        }
        
        uint256[] memory senderMessageIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount && index < count; i++) {
            if (messages[i].sender == _sender) {
                senderMessageIds[index] = i;
                index++;
            }
        }
        
        return senderMessageIds;
    }
    
    /**
     * @dev Get total number of messages
     * @return The total number of messages posted
     */
    function getTotalMessages() external view returns (uint256) {
        return messageCount;
    }
}
