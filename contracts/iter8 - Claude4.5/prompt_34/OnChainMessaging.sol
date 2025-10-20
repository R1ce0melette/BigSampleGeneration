// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OnChainMessaging
 * @dev Contract that lets users send on-chain messages that can be liked by others
 */
contract OnChainMessaging {
    // Message structure
    struct Message {
        uint256 id;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likeCount;
        uint256 replyCount;
        uint256 parentMessageId;
        bool isReply;
    }

    // Like structure
    struct Like {
        address liker;
        uint256 messageId;
        uint256 timestamp;
    }

    // User statistics
    struct UserStats {
        uint256 messagesSent;
        uint256 repliesSent;
        uint256 likesReceived;
        uint256 likesGiven;
        uint256 totalMessages;
    }

    // State variables
    address public owner;
    uint256 private messageCounter;

    mapping(uint256 => Message) private messages;
    mapping(uint256 => address[]) private messageLikers;
    mapping(uint256 => mapping(address => bool)) private hasLiked;
    mapping(address => uint256[]) private userMessages;
    mapping(uint256 => uint256[]) private messageReplies;
    mapping(address => UserStats) private userStats;
    mapping(uint256 => Like[]) private messageLikes;

    uint256[] private allMessageIds;

    // Events
    event MessageSent(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    event ReplyPosted(uint256 indexed messageId, uint256 indexed parentMessageId, address indexed sender);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 timestamp);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 timestamp);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier messageExists(uint256 messageId) {
        require(messageId > 0 && messageId <= messageCounter, "Message does not exist");
        _;
    }

    modifier hasNotLiked(uint256 messageId) {
        require(!hasLiked[messageId][msg.sender], "Already liked this message");
        _;
    }

    modifier hasLikedMessage(uint256 messageId) {
        require(hasLiked[messageId][msg.sender], "Have not liked this message");
        _;
    }

    constructor() {
        owner = msg.sender;
        messageCounter = 0;
    }

    /**
     * @dev Send a message
     * @param content Message content
     * @return messageId ID of the sent message
     */
    function sendMessage(string memory content) public returns (uint256) {
        require(bytes(content).length > 0, "Message content cannot be empty");
        require(bytes(content).length <= 1000, "Message content too long");

        messageCounter++;
        uint256 messageId = messageCounter;

        Message storage newMessage = messages[messageId];
        newMessage.id = messageId;
        newMessage.sender = msg.sender;
        newMessage.content = content;
        newMessage.timestamp = block.timestamp;
        newMessage.likeCount = 0;
        newMessage.replyCount = 0;
        newMessage.parentMessageId = 0;
        newMessage.isReply = false;

        userMessages[msg.sender].push(messageId);
        allMessageIds.push(messageId);

        // Update statistics
        userStats[msg.sender].messagesSent++;
        userStats[msg.sender].totalMessages++;

        emit MessageSent(messageId, msg.sender, content, block.timestamp);

        return messageId;
    }

    /**
     * @dev Reply to a message
     * @param parentMessageId Parent message ID
     * @param content Reply content
     * @return messageId ID of the reply message
     */
    function replyToMessage(uint256 parentMessageId, string memory content) 
        public 
        messageExists(parentMessageId) 
        returns (uint256) 
    {
        require(bytes(content).length > 0, "Reply content cannot be empty");
        require(bytes(content).length <= 1000, "Reply content too long");

        messageCounter++;
        uint256 messageId = messageCounter;

        Message storage newMessage = messages[messageId];
        newMessage.id = messageId;
        newMessage.sender = msg.sender;
        newMessage.content = content;
        newMessage.timestamp = block.timestamp;
        newMessage.likeCount = 0;
        newMessage.replyCount = 0;
        newMessage.parentMessageId = parentMessageId;
        newMessage.isReply = true;

        userMessages[msg.sender].push(messageId);
        allMessageIds.push(messageId);
        messageReplies[parentMessageId].push(messageId);

        // Update parent message reply count
        messages[parentMessageId].replyCount++;

        // Update statistics
        userStats[msg.sender].repliesSent++;
        userStats[msg.sender].totalMessages++;

        emit MessageSent(messageId, msg.sender, content, block.timestamp);
        emit ReplyPosted(messageId, parentMessageId, msg.sender);

        return messageId;
    }

    /**
     * @dev Like a message
     * @param messageId Message ID to like
     */
    function likeMessage(uint256 messageId) 
        public 
        messageExists(messageId) 
        hasNotLiked(messageId) 
    {
        Message storage message = messages[messageId];
        
        hasLiked[messageId][msg.sender] = true;
        messageLikers[messageId].push(msg.sender);
        message.likeCount++;

        Like memory newLike = Like({
            liker: msg.sender,
            messageId: messageId,
            timestamp: block.timestamp
        });

        messageLikes[messageId].push(newLike);

        // Update statistics
        userStats[message.sender].likesReceived++;
        userStats[msg.sender].likesGiven++;

        emit MessageLiked(messageId, msg.sender, block.timestamp);
    }

    /**
     * @dev Unlike a message
     * @param messageId Message ID to unlike
     */
    function unlikeMessage(uint256 messageId) 
        public 
        messageExists(messageId) 
        hasLikedMessage(messageId) 
    {
        Message storage message = messages[messageId];
        
        hasLiked[messageId][msg.sender] = false;
        message.likeCount--;

        // Remove from likers array
        address[] storage likers = messageLikers[messageId];
        for (uint256 i = 0; i < likers.length; i++) {
            if (likers[i] == msg.sender) {
                likers[i] = likers[likers.length - 1];
                likers.pop();
                break;
            }
        }

        // Update statistics
        userStats[message.sender].likesReceived--;
        userStats[msg.sender].likesGiven--;

        emit MessageUnliked(messageId, msg.sender, block.timestamp);
    }

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
     * @dev Get message likers
     * @param messageId Message ID
     * @return Array of liker addresses
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
     * @dev Get message likes
     * @param messageId Message ID
     * @return Array of likes
     */
    function getMessageLikes(uint256 messageId) 
        public 
        view 
        messageExists(messageId) 
        returns (Like[] memory) 
    {
        return messageLikes[messageId];
    }

    /**
     * @dev Get message replies
     * @param messageId Message ID
     * @return Array of reply message IDs
     */
    function getMessageReplies(uint256 messageId) 
        public 
        view 
        messageExists(messageId) 
        returns (uint256[] memory) 
    {
        return messageReplies[messageId];
    }

    /**
     * @dev Get reply messages with details
     * @param messageId Message ID
     * @return Array of reply messages
     */
    function getReplyMessages(uint256 messageId) 
        public 
        view 
        messageExists(messageId) 
        returns (Message[] memory) 
    {
        uint256[] memory replyIds = messageReplies[messageId];
        Message[] memory replies = new Message[](replyIds.length);

        for (uint256 i = 0; i < replyIds.length; i++) {
            replies[i] = messages[replyIds[i]];
        }

        return replies;
    }

    /**
     * @dev Check if user has liked a message
     * @param messageId Message ID
     * @param user User address
     * @return true if liked
     */
    function hasUserLiked(uint256 messageId, address user) 
        public 
        view 
        messageExists(messageId) 
        returns (bool) 
    {
        return hasLiked[messageId][user];
    }

    /**
     * @dev Get user messages
     * @param user User address
     * @return Array of message IDs
     */
    function getUserMessages(address user) public view returns (uint256[] memory) {
        return userMessages[user];
    }

    /**
     * @dev Get user messages with details
     * @param user User address
     * @return Array of messages
     */
    function getUserMessageDetails(address user) public view returns (Message[] memory) {
        uint256[] memory messageIds = userMessages[user];
        Message[] memory userMsgs = new Message[](messageIds.length);

        for (uint256 i = 0; i < messageIds.length; i++) {
            userMsgs[i] = messages[messageIds[i]];
        }

        return userMsgs;
    }

    /**
     * @dev Get all messages
     * @return Array of all messages
     */
    function getAllMessages() public view returns (Message[] memory) {
        Message[] memory allMessages = new Message[](allMessageIds.length);
        
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            allMessages[i] = messages[allMessageIds[i]];
        }
        
        return allMessages;
    }

    /**
     * @dev Get all message IDs
     * @return Array of message IDs
     */
    function getAllMessageIds() public view returns (uint256[] memory) {
        return allMessageIds;
    }

    /**
     * @dev Get recent messages
     * @param count Number of recent messages to return
     * @return Array of recent messages
     */
    function getRecentMessages(uint256 count) public view returns (Message[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 resultCount = count > allMessageIds.length ? allMessageIds.length : count;
        Message[] memory result = new Message[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            uint256 index = allMessageIds.length - 1 - i;
            result[i] = messages[allMessageIds[index]];
        }

        return result;
    }

    /**
     * @dev Get top-level messages (not replies)
     * @return Array of top-level messages
     */
    function getTopLevelMessages() public view returns (Message[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            if (!messages[allMessageIds[i]].isReply) {
                count++;
            }
        }

        Message[] memory result = new Message[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allMessageIds.length; i++) {
            Message memory message = messages[allMessageIds[i]];
            if (!message.isReply) {
                result[index] = message;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get most liked messages
     * @param count Number of messages to return
     * @return Array of most liked messages
     */
    function getMostLikedMessages(uint256 count) public view returns (Message[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        Message[] memory sortedMessages = new Message[](allMessageIds.length);
        
        // Copy messages
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            sortedMessages[i] = messages[allMessageIds[i]];
        }

        // Sort by like count (bubble sort)
        for (uint256 i = 0; i < sortedMessages.length; i++) {
            for (uint256 j = i + 1; j < sortedMessages.length; j++) {
                if (sortedMessages[i].likeCount < sortedMessages[j].likeCount) {
                    Message memory temp = sortedMessages[i];
                    sortedMessages[i] = sortedMessages[j];
                    sortedMessages[j] = temp;
                }
            }
        }

        // Return top count
        uint256 resultCount = count > allMessageIds.length ? allMessageIds.length : count;
        Message[] memory result = new Message[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = sortedMessages[i];
        }

        return result;
    }

    /**
     * @dev Get messages by time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of messages in time range
     */
    function getMessagesByTimeRange(uint256 startTime, uint256 endTime) 
        public 
        view 
        returns (Message[] memory) 
    {
        uint256 count = 0;
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            Message memory message = messages[allMessageIds[i]];
            if (message.timestamp >= startTime && message.timestamp <= endTime) {
                count++;
            }
        }

        Message[] memory result = new Message[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allMessageIds.length; i++) {
            Message memory message = messages[allMessageIds[i]];
            if (message.timestamp >= startTime && message.timestamp <= endTime) {
                result[index] = message;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return UserStats details
     */
    function getUserStats(address user) public view returns (UserStats memory) {
        return userStats[user];
    }

    /**
     * @dev Get total message count
     * @return Total number of messages
     */
    function getTotalMessageCount() public view returns (uint256) {
        return messageCounter;
    }

    /**
     * @dev Get total like count
     * @return Total number of likes
     */
    function getTotalLikeCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            total += messages[allMessageIds[i]].likeCount;
        }
        return total;
    }

    /**
     * @dev Get total reply count
     * @return Total number of replies
     */
    function getTotalReplyCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            if (messages[allMessageIds[i]].isReply) {
                total++;
            }
        }
        return total;
    }

    /**
     * @dev Get top contributors by message count
     * @param count Number of contributors to return
     * @return Array of addresses
     */
    function getTopContributors(uint256 count) public view returns (address[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        // Get unique senders
        address[] memory senders = new address[](allMessageIds.length);
        uint256 senderCount = 0;

        for (uint256 i = 0; i < allMessageIds.length; i++) {
            address sender = messages[allMessageIds[i]].sender;
            bool found = false;
            
            for (uint256 j = 0; j < senderCount; j++) {
                if (senders[j] == sender) {
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                senders[senderCount] = sender;
                senderCount++;
            }
        }

        // Create array of unique senders
        address[] memory uniqueSenders = new address[](senderCount);
        for (uint256 i = 0; i < senderCount; i++) {
            uniqueSenders[i] = senders[i];
        }

        // Sort by message count (bubble sort)
        for (uint256 i = 0; i < uniqueSenders.length; i++) {
            for (uint256 j = i + 1; j < uniqueSenders.length; j++) {
                if (userStats[uniqueSenders[i]].totalMessages < userStats[uniqueSenders[j]].totalMessages) {
                    address temp = uniqueSenders[i];
                    uniqueSenders[i] = uniqueSenders[j];
                    uniqueSenders[j] = temp;
                }
            }
        }

        // Return top count
        uint256 resultCount = count > senderCount ? senderCount : count;
        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = uniqueSenders[i];
        }

        return result;
    }

    /**
     * @dev Get messages with minimum likes
     * @param minLikes Minimum number of likes
     * @return Array of messages
     */
    function getMessagesWithMinLikes(uint256 minLikes) public view returns (Message[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allMessageIds.length; i++) {
            if (messages[allMessageIds[i]].likeCount >= minLikes) {
                count++;
            }
        }

        Message[] memory result = new Message[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allMessageIds.length; i++) {
            Message memory message = messages[allMessageIds[i]];
            if (message.likeCount >= minLikes) {
                result[index] = message;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }
}
