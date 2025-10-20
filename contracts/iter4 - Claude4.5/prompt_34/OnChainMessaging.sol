// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OnChainMessaging
 * @dev A contract that lets users send on-chain messages that can be liked by others
 */
contract OnChainMessaging {
    struct Message {
        uint256 messageId;
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool isActive;
    }
    
    struct User {
        address userAddress;
        uint256 messagesSent;
        uint256 likesReceived;
        uint256 likesGiven;
        bool isRegistered;
    }
    
    address public owner;
    uint256 public totalMessages;
    uint256 public totalLikes;
    
    mapping(uint256 => Message) public messages;
    mapping(address => uint256[]) public userMessages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(uint256 => address[]) public messageLikers;
    mapping(address => User) public users;
    
    // Events
    event MessageSent(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 timestamp);
    event MessageUnliked(uint256 indexed messageId, address indexed unliker, uint256 timestamp);
    event MessageDeleted(uint256 indexed messageId, address indexed sender, uint256 timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier messageExists(uint256 _messageId) {
        require(messages[_messageId].messageId != 0, "Message does not exist");
        _;
    }
    
    modifier onlyMessageSender(uint256 _messageId) {
        require(messages[_messageId].sender == msg.sender, "Only message sender can call this function");
        _;
    }
    
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Sends a new message
     * @param _content The content of the message
     */
    function sendMessage(string memory _content) external returns (uint256) {
        require(bytes(_content).length > 0, "Message content cannot be empty");
        require(bytes(_content).length <= 1000, "Message content too long");
        
        // Register user if not already registered
        if (!users[msg.sender].isRegistered) {
            users[msg.sender] = User({
                userAddress: msg.sender,
                messagesSent: 0,
                likesReceived: 0,
                likesGiven: 0,
                isRegistered: true
            });
        }
        
        totalMessages++;
        uint256 messageId = totalMessages;
        
        messages[messageId] = Message({
            messageId: messageId,
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            isActive: true
        });
        
        userMessages[msg.sender].push(messageId);
        users[msg.sender].messagesSent++;
        
        emit MessageSent(messageId, msg.sender, _content, block.timestamp);
        
        return messageId;
    }
    
    /**
     * @dev Likes a message
     * @param _messageId The ID of the message to like
     */
    function likeMessage(uint256 _messageId) external messageExists(_messageId) {
        Message storage message = messages[_messageId];
        
        require(message.isActive, "Message is not active");
        require(!hasLiked[_messageId][msg.sender], "Already liked this message");
        require(msg.sender != message.sender, "Cannot like your own message");
        
        // Register user if not already registered
        if (!users[msg.sender].isRegistered) {
            users[msg.sender] = User({
                userAddress: msg.sender,
                messagesSent: 0,
                likesReceived: 0,
                likesGiven: 0,
                isRegistered: true
            });
        }
        
        hasLiked[_messageId][msg.sender] = true;
        message.likes++;
        messageLikers[_messageId].push(msg.sender);
        
        users[message.sender].likesReceived++;
        users[msg.sender].likesGiven++;
        totalLikes++;
        
        emit MessageLiked(_messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Unlikes a message
     * @param _messageId The ID of the message to unlike
     */
    function unlikeMessage(uint256 _messageId) external messageExists(_messageId) {
        Message storage message = messages[_messageId];
        
        require(message.isActive, "Message is not active");
        require(hasLiked[_messageId][msg.sender], "Have not liked this message");
        
        hasLiked[_messageId][msg.sender] = false;
        message.likes--;
        
        users[message.sender].likesReceived--;
        users[msg.sender].likesGiven--;
        totalLikes--;
        
        emit MessageUnliked(_messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Deletes a message (only sender can delete)
     * @param _messageId The ID of the message to delete
     */
    function deleteMessage(uint256 _messageId) external messageExists(_messageId) onlyMessageSender(_messageId) {
        Message storage message = messages[_messageId];
        
        require(message.isActive, "Message already deleted");
        
        message.isActive = false;
        
        emit MessageDeleted(_messageId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Returns message details
     * @param _messageId The ID of the message
     * @return messageId The message ID
     * @return sender The sender's address
     * @return content The message content
     * @return timestamp When the message was sent
     * @return likes Number of likes
     * @return isActive Whether the message is active
     */
    function getMessage(uint256 _messageId) external view messageExists(_messageId) returns (
        uint256 messageId,
        address sender,
        string memory content,
        uint256 timestamp,
        uint256 likes,
        bool isActive
    ) {
        Message memory message = messages[_messageId];
        
        return (
            message.messageId,
            message.sender,
            message.content,
            message.timestamp,
            message.likes,
            message.isActive
        );
    }
    
    /**
     * @dev Returns user details
     * @param _user The address of the user
     * @return userAddress The user's address
     * @return messagesSent Number of messages sent
     * @return likesReceived Number of likes received
     * @return likesGiven Number of likes given
     * @return isRegistered Whether the user is registered
     */
    function getUser(address _user) external view returns (
        address userAddress,
        uint256 messagesSent,
        uint256 likesReceived,
        uint256 likesGiven,
        bool isRegistered
    ) {
        User memory user = users[_user];
        
        return (
            user.userAddress,
            user.messagesSent,
            user.likesReceived,
            user.likesGiven,
            user.isRegistered
        );
    }
    
    /**
     * @dev Returns all messages sent by a user
     * @param _user The address of the user
     * @return Array of message IDs
     */
    function getUserMessages(address _user) external view returns (uint256[] memory) {
        return userMessages[_user];
    }
    
    /**
     * @dev Returns all active messages sent by a user
     * @param _user The address of the user
     * @return Array of message IDs
     */
    function getUserActiveMessages(address _user) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < userMessages[_user].length; i++) {
            uint256 messageId = userMessages[_user][i];
            if (messages[messageId].isActive) {
                count++;
            }
        }
        
        uint256[] memory activeMessages = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userMessages[_user].length; i++) {
            uint256 messageId = userMessages[_user][i];
            if (messages[messageId].isActive) {
                activeMessages[index] = messageId;
                index++;
            }
        }
        
        return activeMessages;
    }
    
    /**
     * @dev Returns all users who liked a message
     * @param _messageId The ID of the message
     * @return Array of user addresses
     */
    function getMessageLikers(uint256 _messageId) external view messageExists(_messageId) returns (address[] memory) {
        return messageLikers[_messageId];
    }
    
    /**
     * @dev Checks if a user has liked a message
     * @param _messageId The ID of the message
     * @param _user The address of the user
     * @return True if liked, false otherwise
     */
    function hasUserLiked(uint256 _messageId, address _user) external view returns (bool) {
        return hasLiked[_messageId][_user];
    }
    
    /**
     * @dev Returns all messages (paginated)
     * @param _startIndex The starting index
     * @param _count The number of messages to return
     * @return Array of message IDs
     */
    function getMessages(uint256 _startIndex, uint256 _count) external view returns (uint256[] memory) {
        require(_startIndex > 0 && _startIndex <= totalMessages, "Invalid start index");
        
        uint256 endIndex = _startIndex + _count - 1;
        if (endIndex > totalMessages) {
            endIndex = totalMessages;
        }
        
        uint256 resultCount = endIndex - _startIndex + 1;
        uint256[] memory result = new uint256[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = _startIndex + i;
        }
        
        return result;
    }
    
    /**
     * @dev Returns all active messages
     * @return Array of message IDs
     */
    function getAllActiveMessages() external view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalMessages; i++) {
            if (messages[i].isActive) {
                count++;
            }
        }
        
        uint256[] memory activeMessages = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalMessages; i++) {
            if (messages[i].isActive) {
                activeMessages[index] = i;
                index++;
            }
        }
        
        return activeMessages;
    }
    
    /**
     * @dev Returns the most liked messages (top N)
     * @param _count The number of top messages to return
     * @return Array of message IDs
     */
    function getTopLikedMessages(uint256 _count) external view returns (uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        if (_count > totalMessages) {
            _count = totalMessages;
        }
        
        uint256[] memory topMessages = new uint256[](_count);
        uint256[] memory topLikes = new uint256[](_count);
        
        for (uint256 i = 1; i <= totalMessages; i++) {
            if (messages[i].isActive) {
                uint256 likes = messages[i].likes;
                
                for (uint256 j = 0; j < _count; j++) {
                    if (likes > topLikes[j]) {
                        // Shift down
                        for (uint256 k = _count - 1; k > j; k--) {
                            topMessages[k] = topMessages[k - 1];
                            topLikes[k] = topLikes[k - 1];
                        }
                        
                        topMessages[j] = i;
                        topLikes[j] = likes;
                        break;
                    }
                }
            }
        }
        
        return topMessages;
    }
    
    /**
     * @dev Returns the caller's messages
     * @return Array of message IDs
     */
    function getMyMessages() external view returns (uint256[] memory) {
        return userMessages[msg.sender];
    }
    
    /**
     * @dev Returns the caller's user details
     * @return userAddress The user's address
     * @return messagesSent Number of messages sent
     * @return likesReceived Number of likes received
     * @return likesGiven Number of likes given
     * @return isRegistered Whether the user is registered
     */
    function getMyProfile() external view returns (
        address userAddress,
        uint256 messagesSent,
        uint256 likesReceived,
        uint256 likesGiven,
        bool isRegistered
    ) {
        User memory user = users[msg.sender];
        
        return (
            user.userAddress,
            user.messagesSent,
            user.likesReceived,
            user.likesGiven,
            user.isRegistered
        );
    }
    
    /**
     * @dev Returns the total number of messages
     * @return Total number of messages
     */
    function getTotalMessages() external view returns (uint256) {
        return totalMessages;
    }
    
    /**
     * @dev Returns the total number of likes
     * @return Total number of likes
     */
    function getTotalLikes() external view returns (uint256) {
        return totalLikes;
    }
    
    /**
     * @dev Returns the total number of active messages
     * @return Number of active messages
     */
    function getActiveMessagesCount() external view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 1; i <= totalMessages; i++) {
            if (messages[i].isActive) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Checks if a user is registered
     * @param _user The address of the user
     * @return True if registered, false otherwise
     */
    function isUserRegistered(address _user) external view returns (bool) {
        return users[_user].isRegistered;
    }
    
    /**
     * @dev Transfers ownership of the contract
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != owner, "New owner must be different");
        
        owner = _newOwner;
    }
}
