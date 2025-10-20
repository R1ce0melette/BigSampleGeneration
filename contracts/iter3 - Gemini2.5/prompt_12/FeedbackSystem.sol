// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeedbackSystem
 * @dev A contract for recording user feedback and ratings on a scale of 1 to 5 stars.
 */
contract FeedbackSystem {
    struct Feedback {
        uint256 id;
        address user;
        uint8 rating; // 1 to 5 stars
        string comment;
        uint256 timestamp;
    }

    // An array to store all feedback entries
    Feedback[] public allFeedback;
    // Mapping to track if a user has already submitted feedback
    mapping(address => bool) public hasSubmittedFeedback;
    // Counter for generating unique feedback IDs
    uint256 private _feedbackIdCounter;

    /**
     * @dev Emitted when a new feedback is submitted.
     * @param feedbackId The unique ID of the feedback.
     * @param user The address of the user who submitted the feedback.
     * @param rating The rating given by the user (1-5).
     * @param comment The comment provided by the user.
     */
    event FeedbackSubmitted(
        uint256 indexed feedbackId,
        address indexed user,
        uint8 rating,
        string comment
    );

    /**
     * @dev Allows a user to submit their feedback and rating.
     * A user can only submit feedback once.
     * @param _rating The rating from 1 to 5.
     * @param _comment A text comment for the feedback.
     */
    function submitFeedback(uint8 _rating, string memory _comment) public {
        require(!hasSubmittedFeedback[msg.sender], "You have already submitted feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        hasSubmittedFeedback[msg.sender] = true;
        _feedbackIdCounter++;
        
        Feedback memory newFeedback = Feedback({
            id: _feedbackIdCounter,
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });

        allFeedback.push(newFeedback);

        emit FeedbackSubmitted(_feedbackIdCounter, msg.sender, _rating, _comment);
    }

    /**
     * @dev Retrieves a specific feedback entry by its ID.
     * @param _feedbackId The ID of the feedback to retrieve.
     * @return A tuple containing the feedback details: ID, user address, rating, comment, and timestamp.
     */
    function getFeedbackById(uint256 _feedbackId) public view returns (uint256, address, uint8, string memory, uint256) {
        require(_feedbackId > 0 && _feedbackId <= allFeedback.length, "Feedback ID is out of bounds.");
        Feedback storage feedbackItem = allFeedback[_feedbackId - 1];
        return (feedbackItem.id, feedbackItem.user, feedbackItem.rating, feedbackItem.comment, feedbackItem.timestamp);
    }

    /**
     * @dev Returns the total number of feedback entries submitted.
     * @return The total count of feedback entries.
     */
    function getTotalFeedbackCount() public view returns (uint256) {
        return allFeedback.length;
    }

    /**
     * @dev Checks if a specific user has already submitted feedback.
     * @param _user The address of the user to check.
     * @return True if the user has submitted feedback, false otherwise.
     */
    function hasUserSubmittedFeedback(address _user) public view returns (bool) {
        return hasSubmittedFeedback[_user];
    }
}
