// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        uint256 messageId;
        address author;
        string content;
        uint256 timestamp;
    }
    
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message cannot be empty");
        require(bytes(_content).length <= 1000, "Message too long");
        
        messageCount++;
        
        messages[messageCount] = Message({
            messageId: messageCount,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });
        
        emit MessagePosted(messageCount, msg.sender, _content, block.timestamp);
    }
    
    function getMessage(uint256 _messageId) external view returns (
        uint256 messageId,
        address author,
        string memory content,
        uint256 timestamp
    ) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        Message memory message = messages[_messageId];
        
        return (
            message.messageId,
            message.author,
            message.content,
            message.timestamp
        );
    }
    
    function getRecentMessages(uint256 _count) external view returns (Message[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > messageCount ? messageCount : _count;
        Message[] memory recentMessages = new Message[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentMessages[i] = messages[messageCount - i];
        }
        
        return recentMessages;
    }
    
    function getMessagesByAuthor(address _author) external view returns (uint256[] memory) {
        uint256 authorMessageCount = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == _author) {
                authorMessageCount++;
            }
        }
        
        uint256[] memory authorMessages = new uint256[](authorMessageCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].author == _author) {
                authorMessages[index] = i;
                index++;
            }
        }
        
        return authorMessages;
    }
}
