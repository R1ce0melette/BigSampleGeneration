// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MessagingWithLikes
 * @dev A contract for sending on-chain messages that can be liked.
 */
contract MessagingWithLikes {

    struct Message {
        uint256 id;
        string content;
        address sender;
        uint256 likes;
        mapping(address => bool) hasLiked;
    }

    uint256 public messageCount;
    mapping(uint256 => Message) public messages;

    event MessageSent(uint256 indexed messageId, string content, address indexed sender);
    event Liked(uint256 indexed messageId, address indexed liker);

    /**
     * @dev Sends a new message.
     */
    function sendMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");

        uint256 messageId = messageCount;
        Message storage msg_ = messages[messageId];
        msg_.id = messageId;
        msg_.content = _content;
        msg_.sender = msg.sender;
        msg_.likes = 0;
        
        messageCount++;
        emit MessageSent(messageId, _content, msg.sender);
    }

    /**
     * @dev Likes a message.
     */
    function likeMessage(uint256 _messageId) public {
        Message storage msg_ = messages[_messageId];
        require(msg_.sender != address(0), "Message does not exist.");
        require(!msg_.hasLiked[msg.sender], "You have already liked this message.");

        msg_.hasLiked[msg.sender] = true;
        msg_.likes++;
        emit Liked(_messageId, msg.sender);
    }
}
