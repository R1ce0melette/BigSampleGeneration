// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageLikes {
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 likes;
        uint256 timestamp;
        bool exists;
    }

    uint256 public messageCount;
    mapping(uint256 => Message) public messages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256[]) public userMessages;

    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 totalLikes);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 totalLikes);

    modifier messageExists(uint256 messageId) {
        require(messageId > 0 && messageId <= messageCount, "Message does not exist");
        require(messages[messageId].exists, "Message does not exist");
        _;
    }

    function postMessage(string memory content) external returns (uint256) {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(bytes(content).length <= 1000, "Message too long");

        messageCount++;

        messages[messageCount] = Message({
            id: messageCount,
            author: msg.sender,
            content: content,
            likes: 0,
            timestamp: block.timestamp,
            exists: true
        });

        userMessages[msg.sender].push(messageCount);

        emit MessagePosted(messageCount, msg.sender, content, block.timestamp);

        return messageCount;
    }

    function likeMessage(uint256 messageId) external messageExists(messageId) {
        require(!hasLiked[messageId][msg.sender], "Already liked this message");
        require(messages[messageId].author != msg.sender, "Cannot like your own message");

        hasLiked[messageId][msg.sender] = true;
        messages[messageId].likes++;

        emit MessageLiked(messageId, msg.sender, messages[messageId].likes);
    }

    function unlikeMessage(uint256 messageId) external messageExists(messageId) {
        require(hasLiked[messageId][msg.sender], "Have not liked this message");

        hasLiked[messageId][msg.sender] = false;
        messages[messageId].likes--;

        emit MessageUnliked(messageId, msg.sender, messages[messageId].likes);
    }

    function getMessage(uint256 messageId) external view messageExists(messageId) returns (
        uint256 id,
        address author,
        string memory content,
        uint256 likes,
        uint256 timestamp
    ) {
        Message memory message = messages[messageId];
        return (message.id, message.author, message.content, message.likes, message.timestamp);
    }

    function getUserMessages(address user) external view returns (uint256[] memory) {
        return userMessages[user];
    }

    function hasUserLiked(uint256 messageId, address user) external view messageExists(messageId) returns (bool) {
        return hasLiked[messageId][user];
    }

    function getLatestMessages(uint256 count) external view returns (Message[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > messageCount ? messageCount : count;
        Message[] memory latestMessages = new Message[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            latestMessages[i] = messages[messageCount - i];
        }

        return latestMessages;
    }

    function getMessagesByAuthor(address author) external view returns (Message[] memory) {
        uint256[] memory messageIds = userMessages[author];
        Message[] memory authorMessages = new Message[](messageIds.length);

        for (uint256 i = 0; i < messageIds.length; i++) {
            authorMessages[i] = messages[messageIds[i]];
        }

        return authorMessages;
    }

    function getMostLikedMessages(uint256 count) external view returns (Message[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > messageCount ? messageCount : count;
        Message[] memory topMessages = new Message[](resultCount);
        uint256[] memory topMessageIds = new uint256[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 maxLikes = 0;
            uint256 maxMessageId = 0;

            for (uint256 j = 1; j <= messageCount; j++) {
                if (messages[j].likes > maxLikes) {
                    bool alreadyAdded = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (topMessageIds[k] == j) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    
                    if (!alreadyAdded) {
                        maxLikes = messages[j].likes;
                        maxMessageId = j;
                    }
                }
            }

            if (maxMessageId > 0) {
                topMessages[i] = messages[maxMessageId];
                topMessageIds[i] = maxMessageId;
            }
        }

        return topMessages;
    }

    function getAllMessages() external view returns (Message[] memory) {
        Message[] memory allMessages = new Message[](messageCount);

        for (uint256 i = 1; i <= messageCount; i++) {
            allMessages[i - 1] = messages[i];
        }

        return allMessages;
    }

    function getTotalLikes(address author) external view returns (uint256) {
        uint256 totalLikes = 0;
        uint256[] memory messageIds = userMessages[author];

        for (uint256 i = 0; i < messageIds.length; i++) {
            totalLikes += messages[messageIds[i]].likes;
        }

        return totalLikes;
    }
}
