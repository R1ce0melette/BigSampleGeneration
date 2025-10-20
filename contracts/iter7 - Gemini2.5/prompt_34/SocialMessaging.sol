// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SocialMessaging
 * @dev A contract that allows users to send on-chain messages which can be liked by others.
 */
contract SocialMessaging {
    // Struct to represent a message.
    struct Message {
        uint256 id;
        string content;
        address author;
        uint256 likeCount;
        mapping(address => bool) hasLiked;
    }

    // Counter for generating unique message IDs.
    uint256 private _messageIds;

    // Mapping from message ID to the Message struct.
    mapping(uint256 => Message) public messages;

    /**
     * @dev Emitted when a new message is posted.
     * @param messageId The unique ID of the message.
     * @param author The address of the message author.
     * @param content The content of the message.
     */
    event MessagePosted(uint256 indexed messageId, address indexed author, string content);

    /**
     * @dev Emitted when a message is liked.
     * @param messageId The ID of the liked message.
     * @param liker The address of the user who liked the message.
     */
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    /**
     * @dev Posts a new message.
     * @param _content The content of the message.
     */
    function postMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");
        _messageIds++;
        uint256 newMessageId = _messageIds;

        Message storage msgData = messages[newMessageId];
        msgData.id = newMessageId;
        msgData.content = _content;
        msgData.author = msg.sender;
        msgData.likeCount = 0;

        emit MessagePosted(newMessageId, msg.sender, _content);
    }

    /**
     * @dev Allows a user to like a message.
     * A user cannot like their own message and can only like a message once.
     * @param _messageId The ID of the message to like.
     */
    function likeMessage(uint256 _messageId) public {
        Message storage msgData = messages[_messageId];
        require(msgData.id != 0, "Message does not exist.");
        require(msgData.author != msg.sender, "You cannot like your own message.");
        require(!msgData.hasLiked[msg.sender], "You have already liked this message.");

        msgData.hasLiked[msg.sender] = true;
        msgData.likeCount++;

        emit MessageLiked(_messageId, msg.sender);
    }

    /**
     * @dev Retrieves the details of a specific message.
     * @param _messageId The ID of the message to retrieve.
     * @return The ID, content, author, and like count of the message.
     */
    function getMessage(uint256 _messageId) public view returns (uint256, string memory, address, uint256) {
        Message storage msgData = messages[_messageId];
        require(msgData.id != 0, "Message does not exist.");
        return (msgData.id, msgData.content, msgData.author, msgData.likeCount);
    }

    /**
     * @dev Returns the total number of messages posted.
     * @return The total count of messages.
     */
    function getMessageCount() public view returns (uint256) {
        return _messageIds;
    }
}
