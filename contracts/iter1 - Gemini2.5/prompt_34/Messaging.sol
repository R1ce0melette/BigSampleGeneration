// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Messaging {

    struct Message {
        address sender;
        string content;
        uint256 likeCount;
        mapping(address => bool) likers;
    }

    Message[] public messages;

    event MessageSent(uint256 indexed messageId, address indexed sender, string content);
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    function sendMessage(string calldata _content) public {
        uint256 messageId = messages.length;
        Message storage newMessage = messages.push();
        newMessage.sender = msg.sender;
        newMessage.content = _content;
        
        emit MessageSent(messageId, msg.sender, _content);
    }

    function likeMessage(uint256 _messageId) public {
        require(_messageId < messages.length, "Message does not exist.");
        Message storage message = messages[_messageId];
        require(!message.likers[msg.sender], "You have already liked this message.");

        message.likers[msg.sender] = true;
        message.likeCount++;
        
        emit MessageLiked(_messageId, msg.sender);
    }

    function getMessage(uint256 _messageId) public view returns (address, string memory, uint256) {
        require(_messageId < messages.length, "Message does not exist.");
        Message storage message = messages[_messageId];
        return (message.sender, message.content, message.likeCount);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
}
