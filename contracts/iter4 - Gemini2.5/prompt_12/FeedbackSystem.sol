// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeedbackSystem {
    struct Feedback {
        address user;
        uint8 rating; // 1 to 5 stars
        string comment;
        uint256 timestamp;
    }

    Feedback[] public allFeedback;
    mapping(address => bool) public hasGivenFeedback;

    event FeedbackSubmitted(address indexed user, uint8 rating, string comment);

    function submitFeedback(uint8 _rating, string memory _comment) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(!hasGivenFeedback[msg.sender], "You have already submitted feedback.");

        hasGivenFeedback[msg.sender] = true;
        allFeedback.push(Feedback(msg.sender, _rating, _comment, block.timestamp));

        emit FeedbackSubmitted(msg.sender, _rating, _comment);
    }

    function getFeedbackCount() public view returns (uint256) {
        return allFeedback.length;
    }

    function getFeedback(uint256 _index) public view returns (address, uint8, string memory, uint256) {
        require(_index < allFeedback.length, "Feedback index out of bounds.");
        Feedback storage feedbackItem = allFeedback[_index];
        return (feedbackItem.user, feedbackItem.rating, feedbackItem.comment, feedbackItem.timestamp);
    }
}
