// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Messaging {
    struct Message {
        uint id;
        string content;
        address sender;
        uint likeCount;
    }

    Message[] public messages;
    uint public messageCount;
    mapping(uint => mapping(address => bool)) public hasLiked;

    event MessageSent(uint id, string content, address indexed sender);
    event Liked(uint messageId, address indexed liker);

    function sendMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");
        messageCount++;
        messages.push(Message(messageCount, _content, msg.sender, 0));
        emit MessageSent(messageCount, _content, msg.sender);
    }

    function likeMessage(uint _messageId) public {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist.");
        require(!hasLiked[_messageId][msg.sender], "You have already liked this message.");
        
        Message storage message = messages[_messageId - 1];
        require(message.sender != msg.sender, "You cannot like your own message.");

        hasLiked[_messageId][msg.sender] = true;
        message.likeCount++;
        emit Liked(_messageId, msg.sender);
    }

    function getMessage(uint _messageId) public view returns (uint, string memory, address, uint) {
        require(_messageId > 0 && _messageId <= messageCount, "Message does not exist.");
        Message storage message = messages[_messageId - 1];
        return (message.id, message.content, message.sender, message.likeCount);
    }
}
