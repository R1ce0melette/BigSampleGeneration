// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FeedbackSystem
 * @dev A contract that records user feedback and ratings from 1 to 5 stars
 */
contract FeedbackSystem {
    // Feedback structure
    struct Feedback {
        uint256 id;
        address user;
        uint8 rating;
        string comment;
        uint256 timestamp;
    }
    
    // State variables
    uint256 public feedbackCount;
    mapping(uint256 => Feedback) public feedbacks;
    mapping(address => uint256[]) public userFeedbackIds;
    
    // Rating statistics
    uint256 public totalRatings;
    uint256 public sumOfRatings;
    mapping(uint8 => uint256) public ratingCounts; // Count of each rating (1-5)
    
    // Events
    event FeedbackSubmitted(uint256 indexed feedbackId, address indexed user, uint8 rating, uint256 timestamp);
    event FeedbackUpdated(uint256 indexed feedbackId, uint8 oldRating, uint8 newRating);
    
    /**
     * @dev Submit feedback with rating and comment
     * @param rating The rating from 1 to 5 stars
     * @param comment The feedback comment
     * @return feedbackId The ID of the submitted feedback
     */
    function submitFeedback(uint8 rating, string memory comment) external returns (uint256) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(bytes(comment).length > 0, "Comment cannot be empty");
        require(bytes(comment).length <= 500, "Comment too long");
        
        feedbackCount++;
        uint256 feedbackId = feedbackCount;
        
        feedbacks[feedbackId] = Feedback({
            id: feedbackId,
            user: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        });
        
        userFeedbackIds[msg.sender].push(feedbackId);
        
        // Update statistics
        totalRatings++;
        sumOfRatings += rating;
        ratingCounts[rating]++;
        
        emit FeedbackSubmitted(feedbackId, msg.sender, rating, block.timestamp);
        
        return feedbackId;
    }
    
    /**
     * @dev Submit feedback with only rating (no comment)
     * @param rating The rating from 1 to 5 stars
     * @return feedbackId The ID of the submitted feedback
     */
    function submitRating(uint8 rating) external returns (uint256) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        
        feedbackCount++;
        uint256 feedbackId = feedbackCount;
        
        feedbacks[feedbackId] = Feedback({
            id: feedbackId,
            user: msg.sender,
            rating: rating,
            comment: "",
            timestamp: block.timestamp
        });
        
        userFeedbackIds[msg.sender].push(feedbackId);
        
        // Update statistics
        totalRatings++;
        sumOfRatings += rating;
        ratingCounts[rating]++;
        
        emit FeedbackSubmitted(feedbackId, msg.sender, rating, block.timestamp);
        
        return feedbackId;
    }
    
    /**
     * @dev Update existing feedback rating
     * @param feedbackId The ID of the feedback to update
     * @param newRating The new rating from 1 to 5 stars
     */
    function updateRating(uint256 feedbackId, uint8 newRating) external {
        require(feedbackId > 0 && feedbackId <= feedbackCount, "Invalid feedback ID");
        require(newRating >= 1 && newRating <= 5, "Rating must be between 1 and 5");
        
        Feedback storage feedback = feedbacks[feedbackId];
        require(feedback.user == msg.sender, "Only feedback author can update");
        
        uint8 oldRating = feedback.rating;
        require(oldRating != newRating, "New rating is the same as old rating");
        
        // Update statistics
        sumOfRatings = sumOfRatings - oldRating + newRating;
        ratingCounts[oldRating]--;
        ratingCounts[newRating]++;
        
        feedback.rating = newRating;
        
        emit FeedbackUpdated(feedbackId, oldRating, newRating);
    }
    
    /**
     * @dev Update existing feedback comment
     * @param feedbackId The ID of the feedback to update
     * @param newComment The new comment
     */
    function updateComment(uint256 feedbackId, string memory newComment) external {
        require(feedbackId > 0 && feedbackId <= feedbackCount, "Invalid feedback ID");
        require(bytes(newComment).length > 0, "Comment cannot be empty");
        require(bytes(newComment).length <= 500, "Comment too long");
        
        Feedback storage feedback = feedbacks[feedbackId];
        require(feedback.user == msg.sender, "Only feedback author can update");
        
        feedback.comment = newComment;
    }
    
    /**
     * @dev Get feedback details
     * @param feedbackId The ID of the feedback
     * @return id The feedback ID
     * @return user The user who submitted the feedback
     * @return rating The rating
     * @return comment The comment
     * @return timestamp The submission timestamp
     */
    function getFeedback(uint256 feedbackId) external view returns (
        uint256 id,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(feedbackId > 0 && feedbackId <= feedbackCount, "Invalid feedback ID");
        
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
     * @dev Get all feedback IDs submitted by a user
     * @param user The user address
     * @return Array of feedback IDs
     */
    function getUserFeedbacks(address user) external view returns (uint256[] memory) {
        return userFeedbackIds[user];
    }
    
    /**
     * @dev Get the average rating
     * @return The average rating (multiplied by 100 for precision, e.g., 425 = 4.25)
     */
    function getAverageRating() external view returns (uint256) {
        if (totalRatings == 0) {
            return 0;
        }
        return (sumOfRatings * 100) / totalRatings;
    }
    
    /**
     * @dev Get rating distribution
     * @return count1 Number of 1-star ratings
     * @return count2 Number of 2-star ratings
     * @return count3 Number of 3-star ratings
     * @return count4 Number of 4-star ratings
     * @return count5 Number of 5-star ratings
     */
    function getRatingDistribution() external view returns (
        uint256 count1,
        uint256 count2,
        uint256 count3,
        uint256 count4,
        uint256 count5
    ) {
        return (
            ratingCounts[1],
            ratingCounts[2],
            ratingCounts[3],
            ratingCounts[4],
            ratingCounts[5]
        );
    }
    
    /**
     * @dev Get statistics summary
     * @return total Total number of ratings
     * @return average Average rating (multiplied by 100)
     * @return sum Sum of all ratings
     */
    function getStatistics() external view returns (
        uint256 total,
        uint256 average,
        uint256 sum
    ) {
        uint256 avg = 0;
        if (totalRatings > 0) {
            avg = (sumOfRatings * 100) / totalRatings;
        }
        
        return (totalRatings, avg, sumOfRatings);
    }
    
    /**
     * @dev Get recent feedbacks
     * @param count The number of recent feedbacks to retrieve
     * @return Array of recent feedback IDs
     */
    function getRecentFeedbacks(uint256 count) external view returns (uint256[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        uint256 actualCount = count > feedbackCount ? feedbackCount : count;
        uint256[] memory recentIds = new uint256[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            recentIds[i] = feedbackCount - i;
        }
        
        return recentIds;
    }
    
    /**
     * @dev Get all feedbacks (WARNING: may be gas-intensive for large datasets)
     * @return Array of all feedbacks
     */
    function getAllFeedbacks() external view returns (Feedback[] memory) {
        Feedback[] memory allFeedbacks = new Feedback[](feedbackCount);
        
        for (uint256 i = 1; i <= feedbackCount; i++) {
            allFeedbacks[i - 1] = feedbacks[i];
        }
        
        return allFeedbacks;
    }
}
