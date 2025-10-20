// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LikableMessages
 * @dev A contract that allows users to post messages and like messages from others.
 */
contract LikableMessages {
    
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likeCount;
    }

    uint256 public messageCounter;
    mapping(uint256 => Message) public messages;
    // Tracks who has liked which message: messageId => user => bool
    mapping(uint256 => mapping(address => bool)) public hasLiked;

    event MessagePosted(uint256 indexed messageId, address indexed author, string content);
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    /**
     * @dev Posts a new message to the contract.
     * @param _content The content of the message.
     */
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message content cannot be empty.");

        messageCounter++;
        Message storage newMessage = messages[messageCounter];
        newMessage.id = messageCounter;
        newMessage.author = msg.sender;
        newMessage.content = _content;
        newMessage.timestamp = block.timestamp;
        
        emit MessagePosted(messageCounter, msg.sender, _content);
    }

    /**
     * @dev Allows a user to like a message.
     * A user cannot like their own message or like the same message twice.
     * @param _messageId The ID of the message to like.
     */
    function likeMessage(uint256 _messageId) external {
        Message storage msgToLike = messages[_messageId];
        require(msgToLike.id != 0, "Message does not exist.");
        require(msgToLike.author != msg.sender, "You cannot like your own message.");
        require(!hasLiked[_messageId][msg.sender], "You have already liked this message.");

        hasLiked[_messageId][msg.sender] = true;
        msgToLike.likeCount++;

        emit MessageLiked(_messageId, msg.sender);
    }

    /**
     * @dev Retrieves the details of a specific message.
     * @param _messageId The ID of the message.
     * @return The message author, content, timestamp, and like count.
     */
    function getMessage(uint256 _messageId) external view returns (address, string memory, uint256, uint256) {
        Message storage msgData = messages[_messageId];
        require(msgData.id != 0, "Message does not exist.");
        return (msgData.author, msgData.content, msgData.timestamp, msgData.likeCount);
    }

    /**
     * @dev Returns the total number of messages posted.
     * @return The message count.
     */
    function getTotalMessages() external view returns (uint256) {
        return messageCounter;
    }
}
