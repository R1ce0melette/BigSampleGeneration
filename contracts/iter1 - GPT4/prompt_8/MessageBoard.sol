// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    struct Message {
        address sender;
        string text;
        uint256 timestamp;
    }

    Message[] public messages;

    event MessagePosted(address indexed sender, string text, uint256 timestamp);

    function postMessage(string calldata text) external {
        require(bytes(text).length > 0, "Message required");
        messages.push(Message(msg.sender, text, block.timestamp));
        emit MessagePosted(msg.sender, text, block.timestamp);
    }

    function getMessage(uint256 index) external view returns (address, string memory, uint256) {
        require(index < messages.length, "Invalid index");
        Message storage m = messages[index];
        return (m.sender, m.text, m.timestamp);
    }

    function getMessagesCount() external view returns (uint256) {
        return messages.length;
    }
}
