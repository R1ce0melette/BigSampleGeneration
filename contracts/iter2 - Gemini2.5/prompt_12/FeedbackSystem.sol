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

    /**
     * @dev Submits feedback with a rating and a comment.
     * @param _rating A star rating from 1 to 5.
     * @param _comment A text comment for the feedback.
     */
    function submitFeedback(uint8 _rating, string memory _comment) public {
        require(!hasGivenFeedback[msg.sender], "You have already submitted feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_comment).length > 0, "Comment cannot be empty.");

        allFeedback.push(Feedback({
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        }));

        hasGivenFeedback[msg.sender] = true;
        emit FeedbackSubmitted(msg.sender, _rating, _comment);
    }

    /**
     * @dev Retrieves a specific feedback entry by its index.
     * @param _index The index of the feedback in the allFeedback array.
     * @return The user's address, rating, comment, and timestamp.
     */
    function getFeedback(uint256 _index) public view returns (address, uint8, string memory, uint256) {
        require(_index < allFeedback.length, "Feedback index out of bounds.");
        Feedback storage feedbackItem = allFeedback[_index];
        return (feedbackItem.user, feedbackItem.rating, feedbackItem.comment, feedbackItem.timestamp);
    }

    /**
     * @dev Returns the total number of feedback submissions.
     * @return The total count of feedback entries.
     */
    function getFeedbackCount() public view returns (uint256) {
        return allFeedback.length;
    }
}
