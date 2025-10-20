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
    
    event MessagePosted(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message cannot be empty");
        
        messageCount++;
        
        messages[messageCount] = Message({
            id: messageCount,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });
        
        emit MessagePosted(messageCount, msg.sender, _content, block.timestamp);
    }
    
    function getMessage(uint256 _messageId) external view returns (
        uint256 id,
        address sender,
        string memory content,
        uint256 timestamp
    ) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        
        Message memory message = messages[_messageId];
        
        return (
            message.id,
            message.sender,
            message.content,
            message.timestamp
        );
    }
    
    function getAllMessages() external view returns (Message[] memory) {
        Message[] memory allMessages = new Message[](messageCount);
        
        for (uint256 i = 1; i <= messageCount; i++) {
            allMessages[i - 1] = messages[i];
        }
        
        return allMessages;
    }
    
    function getMessagesBySender(address _sender) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].sender == _sender) {
                count++;
            }
        }
        
        uint256[] memory senderMessageIds = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].sender == _sender) {
                senderMessageIds[index] = i;
                index++;
            }
        }
        
        return senderMessageIds;
    }
    
    function getRecentMessages(uint256 _count) external view returns (Message[] memory) {
        uint256 count = _count;
        if (count > messageCount) {
            count = messageCount;
        }
        
        Message[] memory recentMessages = new Message[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentMessages[i] = messages[messageCount - i];
        }
        
        return recentMessages;
    }
}
