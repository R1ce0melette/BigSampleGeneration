// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LikableMessages {
    struct Message {
        uint256 id;
        string content;
        address author;
        uint256 likes;
        mapping(address => bool) hasLiked;
    }

    Message[] public messages;
    uint256 public messageCount;

    event MessageSent(uint256 indexed id, string content, address indexed author);
    event MessageLiked(uint256 indexed messageId, address indexed liker);

    function sendMessage(string memory _content) public {
        messages.push(Message({
            id: messageCount,
            content: _content,
            author: msg.sender,
            likes: 0
        }));
        
        emit MessageSent(messageCount, _content, msg.sender);
        messageCount++;
    }

    function likeMessage(uint256 _messageId) public {
        require(_messageId < messages.length, "Message does not exist.");
        
        Message storage msgToLike = messages[_messageId];
        require(!msgToLike.hasLiked[msg.sender], "You have already liked this message.");
        require(msgToLike.author != msg.sender, "You cannot like your own message.");

        msgToLike.hasLiked[msg.sender] = true;
        msgToLike.likes++;

        emit MessageLiked(_messageId, msg.sender);
    }

    function getMessage(uint256 _messageId) public view returns (uint256, string memory, address, uint256) {
        require(_messageId < messages.length, "Message does not exist.");
        Message storage m = messages[_messageId];
        return (m.id, m.content, m.author, m.likes);
    }
}
