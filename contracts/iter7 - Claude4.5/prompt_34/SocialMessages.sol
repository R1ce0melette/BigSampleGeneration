// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SocialMessages
 * @dev Contract that lets users send on-chain messages that can be liked by others
 */
contract SocialMessages {
    // Message structure
    struct Message {
        uint256 messageId;
        address author;
        string content;
        uint256 timestamp;
        uint256 likeCount;
        bool exists;
    }

    // Like record
    struct Like {
        address liker;
        uint256 messageId;
        uint256 timestamp;
    }

    // User profile structure
    struct UserProfile {
        address userAddress;
        uint256 messageCount;
        uint256 totalLikesReceived;
        uint256 totalLikesGiven;
        bool exists;
    }

    // State variables
    address public owner;
    uint256 private messageIdCounter;
    
    // Mappings
    mapping(uint256 => Message) private messages;
    mapping(uint256 => mapping(address => bool)) private messageLikes;
    mapping(uint256 => address[]) private messageLikers;
    mapping(address => uint256[]) private userMessages;
    mapping(address => uint256[]) private userLikedMessages;
    mapping(address => UserProfile) private userProfiles;
    
    address[] private users;
    mapping(address => bool) private isUser;

    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 timestamp);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 timestamp);
    event MessageDeleted(uint256 indexed messageId, address indexed author, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier messageExists(uint256 messageId) {
        require(messages[messageId].exists, "Message does not exist");
        _;
    }

    modifier onlyMessageAuthor(uint256 messageId) {
        require(messages[messageId].author == msg.sender, "Not message author");
        _;
    }

    constructor() {
        owner = msg.sender;
        messageIdCounter = 1;
    }

    /**
     * @dev Post a new message
     * @param content Message content
     * @return messageId ID of the posted message
     */
    function postMessage(string memory content) public returns (uint256) {
        require(bytes(content).length > 0, "Content cannot be empty");
        require(bytes(content).length <= 1000, "Content too long");

        uint256 messageId = messageIdCounter;
        messageIdCounter++;

        messages[messageId] = Message({
            messageId: messageId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp,
            likeCount: 0,
            exists: true
        });

        userMessages[msg.sender].push(messageId);

        // Update or create user profile
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
            userProfiles[msg.sender] = UserProfile({
                userAddress: msg.sender,
                messageCount: 1,
                totalLikesReceived: 0,
                totalLikesGiven: 0,
                exists: true
            });
        } else {
            userProfiles[msg.sender].messageCount++;
        }

        emit MessagePosted(messageId, msg.sender, content, block.timestamp);

        return messageId;
    }

    /**
     * @dev Like a message
     * @param messageId Message ID to like
     */
    function likeMessage(uint256 messageId) public messageExists(messageId) {
        require(!messageLikes[messageId][msg.sender], "Already liked this message");
        require(messages[messageId].author != msg.sender, "Cannot like own message");

        messageLikes[messageId][msg.sender] = true;
        messages[messageId].likeCount++;
        messageLikers[messageId].push(msg.sender);
        userLikedMessages[msg.sender].push(messageId);

        // Update user profiles
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
            userProfiles[msg.sender] = UserProfile({
                userAddress: msg.sender,
                messageCount: 0,
                totalLikesReceived: 0,
                totalLikesGiven: 1,
                exists: true
            });
        } else {
            userProfiles[msg.sender].totalLikesGiven++;
        }

        userProfiles[messages[messageId].author].totalLikesReceived++;

        emit MessageLiked(messageId, msg.sender, block.timestamp);
    }

    /**
     * @dev Unlike a message
     * @param messageId Message ID to unlike
     */
    function unlikeMessage(uint256 messageId) public messageExists(messageId) {
        require(messageLikes[messageId][msg.sender], "Have not liked this message");

        messageLikes[messageId][msg.sender] = false;
        messages[messageId].likeCount--;

        userProfiles[msg.sender].totalLikesGiven--;
        userProfiles[messages[messageId].author].totalLikesReceived--;

        emit MessageUnliked(messageId, msg.sender, block.timestamp);
    }

    /**
     * @dev Delete a message (only author)
     * @param messageId Message ID to delete
     */
    function deleteMessage(uint256 messageId) 
        public 
        messageExists(messageId) 
        onlyMessageAuthor(messageId) 
    {
        delete messages[messageId];

        emit MessageDeleted(messageId, msg.sender, block.timestamp);
    }

    /**
     * @dev Batch post multiple messages
     * @param contents Array of message contents
     * @return Array of message IDs
     */
    function batchPostMessages(string[] memory contents) public returns (uint256[] memory) {
        require(contents.length > 0, "Empty contents array");
        require(contents.length <= 10, "Cannot post more than 10 messages at once");

        uint256[] memory messageIds = new uint256[](contents.length);

        for (uint256 i = 0; i < contents.length; i++) {
            messageIds[i] = postMessage(contents[i]);
        }

        return messageIds;
    }

    // View Functions

    /**
     * @dev Get message details
     * @param messageId Message ID
     * @return Message details
     */
    function getMessage(uint256 messageId) 
        public 
        view 
        messageExists(messageId) 
        returns (Message memory) 
    {
        return messages[messageId];
    }

    /**
     * @dev Get message content and basic info
     * @param messageId Message ID
     * @return author Message author
     * @return content Message content
     * @return timestamp Message timestamp
     * @return likeCount Number of likes
     */
    function getMessageInfo(uint256 messageId) 
        public 
        view 
        messageExists(messageId) 
        returns (
            address author,
            string memory content,
            uint256 timestamp,
            uint256 likeCount
        ) 
    {
        Message memory msg = messages[messageId];
        return (msg.author, msg.content, msg.timestamp, msg.likeCount);
    }

    /**
     * @dev Get messages posted by a user
     * @param user User address
     * @return Array of message IDs
     */
    function getMessagesByUser(address user) public view returns (uint256[] memory) {
        return userMessages[user];
    }

    /**
     * @dev Get messages liked by a user
     * @param user User address
     * @return Array of message IDs
     */
    function getMessagesLikedByUser(address user) public view returns (uint256[] memory) {
        return userLikedMessages[user];
    }

    /**
     * @dev Get users who liked a message
     * @param messageId Message ID
     * @return Array of user addresses
     */
    function getMessageLikers(uint256 messageId) 
        public 
        view 
        messageExists(messageId) 
        returns (address[] memory) 
    {
        return messageLikers[messageId];
    }

    /**
     * @dev Check if a user liked a message
     * @param messageId Message ID
     * @param user User address
     * @return true if liked
     */
    function hasUserLikedMessage(uint256 messageId, address user) 
        public 
        view 
        messageExists(messageId) 
        returns (bool) 
    {
        return messageLikes[messageId][user];
    }

    /**
     * @dev Get user profile
     * @param user User address
     * @return UserProfile details
     */
    function getUserProfile(address user) public view returns (UserProfile memory) {
        return userProfiles[user];
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return messageCount Number of messages posted
     * @return totalLikesReceived Total likes received
     * @return totalLikesGiven Total likes given
     */
    function getUserStats(address user) 
        public 
        view 
        returns (
            uint256 messageCount,
            uint256 totalLikesReceived,
            uint256 totalLikesGiven
        ) 
    {
        UserProfile memory profile = userProfiles[user];
        return (profile.messageCount, profile.totalLikesReceived, profile.totalLikesGiven);
    }

    /**
     * @dev Get all users
     * @return Array of user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    /**
     * @dev Get total number of messages
     * @return Total message count
     */
    function getTotalMessages() public view returns (uint256) {
        return messageIdCounter - 1;
    }

    /**
     * @dev Get total number of users
     * @return Total user count
     */
    function getTotalUsers() public view returns (uint256) {
        return users.length;
    }

    /**
     * @dev Get recent messages
     * @param count Number of recent messages to retrieve
     * @return Array of message IDs (most recent first)
     */
    function getRecentMessages(uint256 count) public view returns (uint256[] memory) {
        if (count == 0 || messageIdCounter == 1) {
            return new uint256[](0);
        }

        uint256 totalMessages = messageIdCounter - 1;
        if (count > totalMessages) {
            count = totalMessages;
        }

        uint256[] memory recentMessages = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = messageIdCounter - 1; i >= 1 && index < count; i--) {
            if (messages[i].exists) {
                recentMessages[index] = i;
                index++;
            }
            if (i == 1) break; // Prevent underflow
        }

        return recentMessages;
    }

    /**
     * @dev Get most liked messages
     * @param count Number of messages to retrieve
     * @return Array of message IDs
     */
    function getMostLikedMessages(uint256 count) public view returns (uint256[] memory) {
        if (count == 0 || messageIdCounter == 1) {
            return new uint256[](0);
        }

        uint256 totalMessages = messageIdCounter - 1;
        if (count > totalMessages) {
            count = totalMessages;
        }

        uint256[] memory topMessages = new uint256[](count);

        // Simple selection sort for top N
        for (uint256 i = 0; i < count; i++) {
            uint256 maxLikes = 0;
            uint256 maxId = 0;

            for (uint256 j = 1; j < messageIdCounter; j++) {
                if (!messages[j].exists) continue;

                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (topMessages[k] == j) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && messages[j].likeCount > maxLikes) {
                    maxLikes = messages[j].likeCount;
                    maxId = j;
                }
            }

            if (maxId > 0) {
                topMessages[i] = maxId;
            }
        }

        return topMessages;
    }

    /**
     * @dev Get most active users by message count
     * @param count Number of users to retrieve
     * @return addresses Array of user addresses
     * @return messageCounts Array of message counts
     */
    function getMostActiveUsers(uint256 count) 
        public 
        view 
        returns (address[] memory addresses, uint256[] memory messageCounts) 
    {
        uint256 userCount = users.length;
        if (count > userCount) {
            count = userCount;
        }

        addresses = new address[](count);
        messageCounts = new uint256[](count);

        // Simple selection sort for top N
        for (uint256 i = 0; i < count; i++) {
            uint256 maxMessages = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == users[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && userProfiles[users[j]].messageCount > maxMessages) {
                    maxMessages = userProfiles[users[j]].messageCount;
                    maxIndex = j;
                }
            }

            if (maxMessages > 0) {
                addresses[i] = users[maxIndex];
                messageCounts[i] = maxMessages;
            }
        }

        return (addresses, messageCounts);
    }

    /**
     * @dev Get users with most likes received
     * @param count Number of users to retrieve
     * @return addresses Array of user addresses
     * @return likesReceived Array of likes received
     */
    function getMostLikedUsers(uint256 count) 
        public 
        view 
        returns (address[] memory addresses, uint256[] memory likesReceived) 
    {
        uint256 userCount = users.length;
        if (count > userCount) {
            count = userCount;
        }

        addresses = new address[](count);
        likesReceived = new uint256[](count);

        // Simple selection sort for top N
        for (uint256 i = 0; i < count; i++) {
            uint256 maxLikes = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < userCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == users[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && userProfiles[users[j]].totalLikesReceived > maxLikes) {
                    maxLikes = userProfiles[users[j]].totalLikesReceived;
                    maxIndex = j;
                }
            }

            if (maxLikes > 0) {
                addresses[i] = users[maxIndex];
                likesReceived[i] = maxLikes;
            }
        }

        return (addresses, likesReceived);
    }

    /**
     * @dev Get messages in a range
     * @param startId Start message ID
     * @param endId End message ID
     * @return Array of message IDs
     */
    function getMessagesInRange(uint256 startId, uint256 endId) public view returns (uint256[] memory) {
        require(startId > 0 && endId >= startId, "Invalid range");
        require(endId < messageIdCounter, "End ID out of bounds");

        uint256 count = 0;
        for (uint256 i = startId; i <= endId; i++) {
            if (messages[i].exists) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = startId; i <= endId; i++) {
            if (messages[i].exists) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total likes across all messages
     * @return Total like count
     */
    function getTotalLikes() public view returns (uint256) {
        uint256 totalLikes = 0;
        for (uint256 i = 1; i < messageIdCounter; i++) {
            if (messages[i].exists) {
                totalLikes += messages[i].likeCount;
            }
        }
        return totalLikes;
    }

    /**
     * @dev Check if message exists
     * @param messageId Message ID
     * @return true if exists
     */
    function messageExistsCheck(uint256 messageId) public view returns (bool) {
        return messages[messageId].exists;
    }

    /**
     * @dev Check if user has posted any messages
     * @param user User address
     * @return true if user has posted
     */
    function hasUserPosted(address user) public view returns (bool) {
        return userProfiles[user].messageCount > 0;
    }
}
