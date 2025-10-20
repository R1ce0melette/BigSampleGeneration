// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        uint256 messageId;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool isActive;
    }
    
    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256[]) public userMessages;
    mapping(address => uint256[]) public userLikedMessages;
    
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 totalLikes);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 totalLikes);
    event MessageDeleted(uint256 indexed messageId, address indexed author);
    
    modifier messageExists(uint256 _messageId) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(messages[_messageId].isActive, "Message is not active");
        _;
    }
    
    modifier onlyMessageAuthor(uint256 _messageId) {
        require(messages[_messageId].author == msg.sender, "Not the message author");
        _;
    }
    
    function postMessage(string memory _content) external returns (uint256) {
        require(bytes(_content).length > 0, "Message content cannot be empty");
        require(bytes(_content).length <= 1000, "Message content too long");
        
        messageCount++;
        
        messages[messageCount] = Message({
            messageId: messageCount,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            isActive: true
        });
        
        userMessages[msg.sender].push(messageCount);
        
        emit MessagePosted(messageCount, msg.sender, _content, block.timestamp);
        
        return messageCount;
    }
    
    function likeMessage(uint256 _messageId) external messageExists(_messageId) {
        require(!hasLiked[_messageId][msg.sender], "Already liked this message");
        require(messages[_messageId].author != msg.sender, "Cannot like your own message");
        
        hasLiked[_messageId][msg.sender] = true;
        messages[_messageId].likes++;
        userLikedMessages[msg.sender].push(_messageId);
        
        emit MessageLiked(_messageId, msg.sender, messages[_messageId].likes);
    }
    
    function unlikeMessage(uint256 _messageId) external messageExists(_messageId) {
        require(hasLiked[_messageId][msg.sender], "You have not liked this message");
        
        hasLiked[_messageId][msg.sender] = false;
        messages[_messageId].likes--;
        
        // Remove from userLikedMessages
        uint256[] storage likedMessages = userLikedMessages[msg.sender];
        for (uint256 i = 0; i < likedMessages.length; i++) {
            if (likedMessages[i] == _messageId) {
                likedMessages[i] = likedMessages[likedMessages.length - 1];
                likedMessages.pop();
                break;
            }
        }
        
        emit MessageUnliked(_messageId, msg.sender, messages[_messageId].likes);
    }
    
    function deleteMessage(uint256 _messageId) external 
        messageExists(_messageId) 
        onlyMessageAuthor(_messageId) 
    {
        messages[_messageId].isActive = false;
        
        emit MessageDeleted(_messageId, msg.sender);
    }
    
    function getMessage(uint256 _messageId) external view messageExists(_messageId) returns (
        address author,
        string memory content,
        uint256 timestamp,
        uint256 likes
    ) {
        Message memory message = messages[_messageId];
        
        return (
            message.author,
            message.content,
            message.timestamp,
            message.likes
        );
    }
    
    function getUserMessages(address _user) external view returns (uint256[] memory) {
        return userMessages[_user];
    }
    
    function getUserActiveMessages(address _user) external view returns (uint256[] memory) {
        uint256[] memory allMessages = userMessages[_user];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].isActive) {
                activeCount++;
            }
        }
        
        uint256[] memory activeMessages = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allMessages.length; i++) {
            if (messages[allMessages[i]].isActive) {
                activeMessages[index] = allMessages[i];
                index++;
            }
        }
        
        return activeMessages;
    }
    
    function getUserLikedMessages(address _user) external view returns (uint256[] memory) {
        return userLikedMessages[_user];
    }
    
    function hasUserLiked(uint256 _messageId, address _user) external view returns (bool) {
        return hasLiked[_messageId][_user];
    }
    
    function getRecentMessages(uint256 _count) external view returns (Message[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 activeCount = 0;
        for (uint256 i = messageCount; i >= 1 && activeCount < _count; i--) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        Message[] memory recentMessages = new Message[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = messageCount; i >= 1 && index < activeCount; i--) {
            if (messages[i].isActive) {
                recentMessages[index] = messages[i];
                index++;
            }
        }
        
        return recentMessages;
    }
    
    function getTopMessages(uint256 _count) external view returns (uint256[] memory, uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        // Count active messages
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].isActive) {
                activeCount++;
            }
        }
        
        uint256 resultCount = _count > activeCount ? activeCount : _count;
        uint256[] memory topMessageIds = new uint256[](resultCount);
        uint256[] memory topLikes = new uint256[](resultCount);
        
        // Simple bubble sort for top messages (not gas efficient for large datasets)
        for (uint256 i = 1; i <= messageCount && resultCount > 0; i++) {
            if (messages[i].isActive) {
                for (uint256 j = 0; j < resultCount; j++) {
                    if (topMessageIds[j] == 0 || messages[i].likes > topLikes[j]) {
                        // Shift elements
                        for (uint256 k = resultCount - 1; k > j; k--) {
                            topMessageIds[k] = topMessageIds[k - 1];
                            topLikes[k] = topLikes[k - 1];
                        }
                        topMessageIds[j] = i;
                        topLikes[j] = messages[i].likes;
                        break;
                    }
                }
            }
        }
        
        return (topMessageIds, topLikes);
    }
    
    function getTotalMessages() external view returns (uint256) {
        return messageCount;
    }
    
    function getActiveMessageCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= messageCount; i++) {
            if (messages[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    function getMessageLikes(uint256 _messageId) external view returns (uint256) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        return messages[_messageId].likes;
    }
}
