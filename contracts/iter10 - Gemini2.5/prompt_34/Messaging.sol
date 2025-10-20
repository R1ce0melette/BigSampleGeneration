// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Messaging {
    struct Message {
        uint256 id;
        string content;
        address sender;
        uint256 likes;
    }

    Message[] public messages;
    uint256 public messageCount;
    mapping(uint256 => mapping(address => bool)) public hasLiked;

    event MessageSent(uint256 id, string content, address indexed sender);
    event MessageLiked(uint256 messageId, address indexed liker);

    function sendMessage(string memory _content) public {
        messageCount++;
        messages.push(Message(messageCount, _content, msg.sender, 0));
        emit MessageSent(messageCount, _content, msg.sender);
    }

    function likeMessage(uint256 _messageId) public {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist.");
        require(!hasLiked[_messageId][msg.sender], "You have already liked this message.");
        
        messages[_messageId - 1].likes++;
        hasLiked[_messageId][msg.sender] = true;
        emit MessageLiked(_messageId, msg.sender);
    }

    function getMessage(uint256 _messageId) public view returns (uint256, string memory, address, uint256) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist.");
        Message storage msg_ = messages[_messageId - 1];
        return (msg_.id, msg_.content, msg_.sender, msg_.likes);
    }
}
