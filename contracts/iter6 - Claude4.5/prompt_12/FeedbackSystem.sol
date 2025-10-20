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
    
    // Mapping to track user's feedback ID
    mapping(address => uint256) public userFeedbackId;
    
    // Rating statistics
    uint256 public totalRatingSum;
    uint256 public totalRatings;
    
    // Events
    event FeedbackSubmitted(uint256 indexed feedbackId, address indexed user, uint8 rating, uint256 timestamp);
    event FeedbackUpdated(uint256 indexed feedbackId, address indexed user, uint8 newRating, uint256 timestamp);
    
    /**
     * @dev Submit feedback with rating and comment
     * @param rating The rating from 1 to 5 stars
     * @param comment The feedback comment
     */
    function submitFeedback(uint8 rating, string memory comment) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(bytes(comment).length > 0, "Comment cannot be empty");
        require(!hasSubmittedFeedback[msg.sender], "Feedback already submitted");
        
        feedbackCount++;
        
        feedbacks[feedbackCount] = Feedback({
            id: feedbackCount,
            user: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        });
        
        hasSubmittedFeedback[msg.sender] = true;
        userFeedbackId[msg.sender] = feedbackCount;
        
        totalRatingSum += rating;
        totalRatings++;
        
        emit FeedbackSubmitted(feedbackCount, msg.sender, rating, block.timestamp);
    }
    
    /**
     * @dev Update existing feedback
     * @param rating The new rating from 1 to 5 stars
     * @param comment The new feedback comment
     */
    function updateFeedback(uint8 rating, string memory comment) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(bytes(comment).length > 0, "Comment cannot be empty");
        require(hasSubmittedFeedback[msg.sender], "No feedback to update");
        
        uint256 feedbackId = userFeedbackId[msg.sender];
        Feedback storage feedback = feedbacks[feedbackId];
        
        // Update rating statistics
        totalRatingSum = totalRatingSum - feedback.rating + rating;
        
        feedback.rating = rating;
        feedback.comment = comment;
        feedback.timestamp = block.timestamp;
        
        emit FeedbackUpdated(feedbackId, msg.sender, rating, block.timestamp);
    }
    
    /**
     * @dev Get feedback by ID
     * @param feedbackId The ID of the feedback
     * @return id The feedback ID
     * @return user The user's address
     * @return rating The rating
     * @return comment The comment
     * @return timestamp The timestamp
     */
    function getFeedback(uint256 feedbackId) external view returns (
        uint256 id,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(feedbackId > 0 && feedbackId <= feedbackCount, "Feedback does not exist");
        Feedback memory feedback = feedbacks[feedbackId];
        
        return (
            feedback.id,
            feedback.user,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    /**
     * @dev Get feedback by user address
     * @param user The address of the user
     * @return id The feedback ID
     * @return rating The rating
     * @return comment The comment
     * @return timestamp The timestamp
     */
    function getFeedbackByUser(address user) external view returns (
        uint256 id,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(hasSubmittedFeedback[user], "User has not submitted feedback");
        
        uint256 feedbackId = userFeedbackId[user];
        Feedback memory feedback = feedbacks[feedbackId];
        
        return (
            feedback.id,
            feedback.rating,
            feedback.comment,
            feedback.timestamp
        );
    }
    
    /**
     * @dev Get the caller's feedback
     * @return id The feedback ID
     * @return rating The rating
     * @return comment The comment
     * @return timestamp The timestamp
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
     * @dev Get the average rating
     * @return The average rating (multiplied by 100 for precision)
     */
    function getAverageRating() external view returns (uint256) {
        if (totalRatings == 0) {
            return 0;
        }
        return (totalRatingSum * 100) / totalRatings;
    }
    
    /**
     * @dev Get rating distribution
     * @return star1 Number of 1-star ratings
     * @return star2 Number of 2-star ratings
     * @return star3 Number of 3-star ratings
     * @return star4 Number of 4-star ratings
     * @return star5 Number of 5-star ratings
     */
    function getRatingDistribution() external view returns (
        uint256 star1,
        uint256 star2,
        uint256 star3,
        uint256 star4,
        uint256 star5
    ) {
        uint256[5] memory distribution;
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            uint8 rating = feedbacks[i].rating;
            distribution[rating - 1]++;
        }
        
        return (
            distribution[0],
            distribution[1],
            distribution[2],
            distribution[3],
            distribution[4]
        );
    }
    
    /**
     * @dev Get all feedback IDs
     * @return Array of all feedback IDs
     */
    function getAllFeedbackIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](feedbackCount);
        for (uint256 i = 0; i < feedbackCount; i++) {
            ids[i] = i + 1;
        }
        return ids;
    }
    
    /**
     * @dev Get feedbacks by rating
     * @param rating The rating to filter by (1-5)
     * @return Array of feedback IDs with the specified rating
     */
    function getFeedbacksByRating(uint8 rating) external view returns (uint256[] memory) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        
        // Count feedbacks with the specified rating
        uint256 count = 0;
        for (uint256 i = 1; i <= feedbackCount; i++) {
            if (feedbacks[i].rating == rating) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory feedbackIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= feedbackCount; i++) {
            if (feedbacks[i].rating == rating) {
                feedbackIds[index] = i;
                index++;
            }
        }
        
        return feedbackIds;
    }
    
    /**
     * @dev Get statistics
     * @return totalFeedbacks Total number of feedbacks
     * @return averageRating Average rating (multiplied by 100)
     * @return totalRatingsCount Total number of ratings
     */
    function getStats() external view returns (
        uint256 totalFeedbacks,
        uint256 averageRating,
        uint256 totalRatingsCount
    ) {
        uint256 avgRating = 0;
        if (totalRatings > 0) {
            avgRating = (totalRatingSum * 100) / totalRatings;
        }
        
        return (
            feedbackCount,
            avgRating,
            totalRatings
        );
    }
}
