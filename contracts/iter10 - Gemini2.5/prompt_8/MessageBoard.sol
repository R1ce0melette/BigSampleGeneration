// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessagePosted(address indexed sender, string content, uint256 timestamp);

    function postMessage(string memory _content) public {
        require(bytes(_content).length > 0, "Message content cannot be empty.");
        messages.push(Message(msg.sender, _content, block.timestamp));
        emit MessagePosted(msg.sender, _content, block.timestamp);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    function getMessage(uint256 _index) public view returns (address, string memory, uint256) {
        require(_index < messages.length, "Message index out of bounds.");
        Message storage msg_ = messages[_index];
        return (msg_.sender, msg_.content, msg_.timestamp);
    }
}
