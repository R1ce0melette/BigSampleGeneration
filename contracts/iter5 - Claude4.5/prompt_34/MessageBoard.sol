// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likeCount;
        bool isActive;
    }
    
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256[]) public userMessages;
    mapping(uint256 => address[]) public messageLikers;
    
    event MessagePosted(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker);
    event MessageDeleted(uint256 indexed messageId);
    
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message cannot be empty");
        require(bytes(_content).length <= 280, "Message too long");
        
        messageCount++;
        
        messages[messageCount] = Message({
            id: messageCount,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likeCount: 0,
            isActive: true
        });
        
        userMessages[msg.sender].push(messageCount);
        
        emit MessagePosted(messageCount, msg.sender, _content, block.timestamp);
    }
    
    function likeMessage(uint256 _messageId) external {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        
        Message storage message = messages[_messageId];
        
        require(message.isActive, "Message is not active");
        require(!hasLiked[_messageId][msg.sender], "Already liked this message");
        require(msg.sender != message.sender, "Cannot like your own message");
        
        hasLiked[_messageId][msg.sender] = true;
        message.likeCount++;
        messageLikers[_messageId].push(msg.sender);
        
        emit MessageLiked(_messageId, msg.sender);
    }
    
    function unlikeMessage(uint256 _messageId) external {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        
        Message storage message = messages[_messageId];
        
        require(message.isActive, "Message is not active");
        require(hasLiked[_messageId][msg.sender], "Haven't liked this message");
        
        hasLiked[_messageId][msg.sender] = false;
        message.likeCount--;
        
        // Remove from likers array
        address[] storage likers = messageLikers[_messageId];
        for (uint256 i = 0; i < likers.length; i++) {
            if (likers[i] == msg.sender) {
                likers[i] = likers[likers.length - 1];
                likers.pop();
                break;
            }
        }
        
        emit MessageUnliked(_messageId, msg.sender);
    }
    
    function deleteMessage(uint256 _messageId) external {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        
        Message storage message = messages[_messageId];
        
        require(msg.sender == message.sender, "Only sender can delete message");
        require(message.isActive, "Message is already deleted");
        
        message.isActive = false;
        
        emit MessageDeleted(_messageId);
    }
    
    function getMessage(uint256 _messageId) external view returns (
        uint256 id,
        address sender,
        string memory content,
        uint256 timestamp,
        uint256 likeCount,
        bool isActive
    ) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        
        Message memory message = messages[_messageId];
        
        return (
            message.id,
            message.sender,
            message.content,
            message.timestamp,
            message.likeCount,
            message.isActive
        );
    }
    
    function hasUserLiked(uint256 _messageId, address _user) external view returns (bool) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        return hasLiked[_messageId][_user];
    }
    
    function getMessageLikers(uint256 _messageId) external view returns (address[] memory) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist");
        return messageLikers[_messageId];
    }
    
    function getUserMessages(address _user) external view returns (uint256[] memory) {
        return userMessages[_user];
    }
    
    function getAllMessages() external view returns (Message[] memory) {
        Message[] memory allMessages = new Message[](messageCount);
        
        for (uint256 i = 1; i <= messageCount; i++) {
            allMessages[i - 1] = messages[i];
        }
        
        return allMessages;
    }
    
    function getActiveMessages() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        uint256[] memory activeMessageIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].isActive) {
                activeMessageIds[index] = i;
                index++;
            }
        }
        
        return activeMessageIds;
    }
    
    function getRecentMessages(uint256 _count) external view returns (Message[] memory) {
        uint256 count = _count;
        if (count > messageCount) {
            count = messageCount;
        }
        
        Message[] memory recentMessages = new Message[](count);
        uint256 index = 0;
        
        for (uint256 i = messageCount; i > 0 && index < count; i--) {
            if (messages[i].isActive) {
                recentMessages[index] = messages[i];
                index++;
            }
        }
        
        return recentMessages;
    }
    
    function getTopLikedMessages(uint256 _count) external view returns (uint256[] memory) {
        uint256 count = _count;
        if (count > messageCount) {
            count = messageCount;
        }
        
        uint256[] memory topMessageIds = new uint256[](count);
        uint256[] memory topLikeCounts = new uint256[](count);
        
        // Simple selection sort for top liked messages
        for (uint256 i = 1; i <= messageCount; i++) {
            if (!messages[i].isActive) continue;
            
            uint256 likes = messages[i].likeCount;
            
            for (uint256 j = 0; j < count; j++) {
                if (likes > topLikeCounts[j]) {
                    // Shift elements down
                    for (uint256 k = count - 1; k > j; k--) {
                        topLikeCounts[k] = topLikeCounts[k - 1];
                        topMessageIds[k] = topMessageIds[k - 1];
                    }
                    
                    topLikeCounts[j] = likes;
                    topMessageIds[j] = i;
                    break;
                }
            }
        }
        
        return topMessageIds;
    }
    
    function getUserMessageCount(address _user) external view returns (uint256) {
        return userMessages[_user].length;
    }
    
    function getTotalActiveMessages() external view returns (uint256) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        return activeCount;
    }
}
