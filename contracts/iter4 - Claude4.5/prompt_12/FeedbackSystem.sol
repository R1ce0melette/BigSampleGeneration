// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FeedbackSystem
 * @dev A contract that records user feedback and ratings from 1 to 5 stars
 */
contract FeedbackSystem {
    struct Feedback {
        uint256 id;
        address user;
        uint8 rating;
        string comment;
        uint256 timestamp;
    }
    
    uint256 public feedbackCount;
    mapping(uint256 => Feedback) public feedbacks;
    
    // Mapping to track if a user has submitted feedback
    mapping(address => bool) public hasSubmittedFeedback;
    
    // Mapping from user address to their feedback ID
    mapping(address => uint256) public userFeedbackId;
    
    // Rating statistics
    uint256 public totalRating;
    uint256 public ratingCount;
    
    // Events
    event FeedbackSubmitted(uint256 indexed feedbackId, address indexed user, uint8 rating, uint256 timestamp);
    event FeedbackUpdated(uint256 indexed feedbackId, address indexed user, uint8 newRating, uint256 timestamp);
    
    /**
     * @dev Allows a user to submit feedback with a rating
     * @param _rating The rating from 1 to 5 stars
     * @param _comment The feedback comment
     */
    function submitFeedback(uint8 _rating, string memory _comment) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(!hasSubmittedFeedback[msg.sender], "Feedback already submitted");
        require(bytes(_comment).length > 0, "Comment cannot be empty");
        
        feedbackCount++;
        
        feedbacks[feedbackCount] = Feedback({
            id: feedbackCount,
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });
        
        hasSubmittedFeedback[msg.sender] = true;
        userFeedbackId[msg.sender] = feedbackCount;
        
        totalRating += _rating;
        ratingCount++;
        
        emit FeedbackSubmitted(feedbackCount, msg.sender, _rating, block.timestamp);
    }
    
    /**
     * @dev Allows a user to update their feedback
     * @param _rating The new rating from 1 to 5 stars
     * @param _comment The new feedback comment
     */
    function updateFeedback(uint8 _rating, string memory _comment) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(hasSubmittedFeedback[msg.sender], "No feedback submitted yet");
        require(bytes(_comment).length > 0, "Comment cannot be empty");
        
        uint256 feedbackId = userFeedbackId[msg.sender];
        Feedback storage feedback = feedbacks[feedbackId];
        
        // Update total rating
        totalRating = totalRating - feedback.rating + _rating;
        
        feedback.rating = _rating;
        feedback.comment = _comment;
        feedback.timestamp = block.timestamp;
        
        emit FeedbackUpdated(feedbackId, msg.sender, _rating, block.timestamp);
    }
    
    /**
     * @dev Returns the feedback details for a specific ID
     * @param _feedbackId The ID of the feedback
     * @return id The feedback ID
     * @return user The user's address
     * @return rating The rating given
     * @return comment The feedback comment
     * @return timestamp When the feedback was submitted/updated
     */
    function getFeedback(uint256 _feedbackId) external view returns (
        uint256 id,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(_feedbackId > 0 && _feedbackId <= feedbackCount, "Invalid feedback ID");
        
        Feedback memory feedback = feedbacks[_feedbackId];
        
        return (
            feedback.id,
            feedback.user,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    /**
     * @dev Returns the feedback submitted by a specific user
     * @param _user The address of the user
     * @return id The feedback ID
     * @return rating The rating given
     * @return comment The feedback comment
     * @return timestamp When the feedback was submitted/updated
     */
    function getFeedbackByUser(address _user) external view returns (
        uint256 id,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(hasSubmittedFeedback[_user], "User has not submitted feedback");
        
        uint256 feedbackId = userFeedbackId[_user];
        Feedback memory feedback = feedbacks[feedbackId];
        
        return (
            feedback.id,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    /**
     * @dev Returns the caller's feedback
     * @return id The feedback ID
     * @return rating The rating given
     * @return comment The feedback comment
     * @return timestamp When the feedback was submitted/updated
     */
    function getMyFeedback() external view returns (
        uint256 id,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(hasSubmittedFeedback[msg.sender], "You have not submitted feedback");
        
        uint256 feedbackId = userFeedbackId[msg.sender];
        Feedback memory feedback = feedbacks[feedbackId];
        
        return (
            feedback.id,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    /**
     * @dev Returns the average rating
     * @return The average rating (scaled by 100 for precision, e.g., 450 = 4.50 stars)
     */
    function getAverageRating() external view returns (uint256) {
        if (ratingCount == 0) {
            return 0;
        }
        return (totalRating * 100) / ratingCount;
    }
    
    /**
     * @dev Returns all feedbacks (use with caution for large datasets)
     * @return Array of all feedbacks
     */
    function getAllFeedbacks() external view returns (Feedback[] memory) {
        Feedback[] memory allFeedbacks = new Feedback[](feedbackCount);
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            allFeedbacks[i - 1] = feedbacks[i];
        }
        
        return allFeedbacks;
    }
    
    /**
     * @dev Returns feedbacks with a specific rating
     * @param _rating The rating to filter by (1-5)
     * @return Array of feedbacks with the specified rating
     */
    function getFeedbacksByRating(uint8 _rating) external view returns (Feedback[] memory) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        
        // Count feedbacks with the specified rating
        uint256 count = 0;
        for (uint256 i = 1; i <= feedbackCount; i++) {
            if (feedbacks[i].rating == _rating) {
                count++;
            }
        }
        
        // Create array and populate it
        Feedback[] memory filteredFeedbacks = new Feedback[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            if (feedbacks[i].rating == _rating) {
                filteredFeedbacks[index] = feedbacks[i];
                index++;
            }
        }
        
        return filteredFeedbacks;
    }
    
    /**
     * @dev Returns the distribution of ratings
     * @return Array of counts for each rating (1-5 stars)
     */
    function getRatingDistribution() external view returns (uint256[5] memory) {
        uint256[5] memory distribution;
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            uint8 rating = feedbacks[i].rating;
            distribution[rating - 1]++;
        }
        
        return distribution;
    }
    
    /**
     * @dev Returns the total number of feedbacks submitted
     * @return The total feedback count
     */
    function getTotalFeedbacks() external view returns (uint256) {
        return feedbackCount;
    }
}
