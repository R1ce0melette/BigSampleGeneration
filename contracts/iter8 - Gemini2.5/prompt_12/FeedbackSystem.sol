// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeedbackSystem
 * @dev A contract for collecting user feedback and ratings on a scale of 1 to 5 stars.
 */
contract FeedbackSystem {
    struct Feedback {
        address user;
        uint8 rating; // 1 to 5 stars
        string comment;
        uint256 timestamp;
    }

    Feedback[] public allFeedback;
    mapping(address => bool) private hasSubmitted;

    event FeedbackSubmitted(address indexed user, uint8 rating, string comment);

    /**
     * @dev Allows a user to submit their feedback and rating.
     * A user can only submit feedback once.
     * @param _rating The star rating from 1 to 5.
     * @param _comment A text comment for the feedback.
     */
    function submitFeedback(uint8 _rating, string memory _comment) public {
        require(!hasSubmitted[msg.sender], "You have already submitted feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        hasSubmitted[msg.sender] = true;
        allFeedback.push(Feedback({
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        }));

        emit FeedbackSubmitted(msg.sender, _rating, _comment);
    }

    /**
     * @dev Returns the total number of feedback entries submitted.
     * @return The total count of feedback entries.
     */
    function getFeedbackCount() public view returns (uint256) {
        return allFeedback.length;
    }

    /**
     * @dev Retrieves a specific feedback entry by its index.
     * @param _index The index of the feedback in the `allFeedback` array.
     * @return The user, rating, comment, and timestamp of the feedback.
     */
    function getFeedback(uint256 _index) public view returns (address, uint8, string memory, uint256) {
        require(_index < allFeedback.length, "Index out of bounds.");
        Feedback storage feedbackItem = allFeedback[_index];
        return (feedbackItem.user, feedbackItem.rating, feedbackItem.comment, feedbackItem.timestamp);
    }
}
