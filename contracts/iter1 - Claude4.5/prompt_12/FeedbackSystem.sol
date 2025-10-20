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
    
    Feedback[] public feedbacks;
    mapping(address => uint256[]) private userFeedbackIds;
    mapping(address => bool) public hasSubmittedFeedback;
    
    uint256 public totalRating;
    uint256 public feedbackCount;
    
    event FeedbackSubmitted(
        uint256 indexed feedbackId,
        address indexed user,
        uint8 rating,
        uint256 timestamp
    );
    
    /**
     * @dev Submit feedback with rating and comment
     * @param rating Rating from 1 to 5 stars
     * @param comment Feedback comment
     * @return feedbackId The ID of the submitted feedback
     */
    function submitFeedback(uint8 rating, string memory comment) external returns (uint256) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(bytes(comment).length > 0, "Comment cannot be empty");
        require(bytes(comment).length <= 1000, "Comment too long");
        
        uint256 feedbackId = feedbacks.length;
        
        Feedback memory newFeedback = Feedback({
            id: feedbackId,
            user: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        });
        
        feedbacks.push(newFeedback);
        userFeedbackIds[msg.sender].push(feedbackId);
        
        if (!hasSubmittedFeedback[msg.sender]) {
            hasSubmittedFeedback[msg.sender] = true;
        }
        
        totalRating += rating;
        feedbackCount++;
        
        emit FeedbackSubmitted(feedbackId, msg.sender, rating, block.timestamp);
        
        return feedbackId;
    }
    
    /**
     * @dev Get a specific feedback by ID
     * @param feedbackId The ID of the feedback
     * @return id Feedback ID
     * @return user Address of the user who submitted
     * @return rating Rating value
     * @return comment Feedback comment
     * @return timestamp When the feedback was submitted
     */
    function getFeedback(uint256 feedbackId) external view returns (
        uint256 id,
        address user,
        uint8 rating,
        string memory comment,
        uint256 timestamp
    ) {
        require(feedbackId < feedbacks.length, "Feedback does not exist");
        
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
     * @dev Get all feedbacks
     * @return Array of all feedbacks
     */
    function getAllFeedbacks() external view returns (Feedback[] memory) {
        return feedbacks;
    }
    
    /**
     * @dev Get feedback IDs submitted by a specific user
     * @param user The address of the user
     * @return Array of feedback IDs
     */
    function getUserFeedbackIds(address user) external view returns (uint256[] memory) {
        return userFeedbackIds[user];
    }
    
    /**
     * @dev Get all feedbacks submitted by a specific user
     * @param user The address of the user
     * @return Array of feedbacks
     */
    function getUserFeedbacks(address user) external view returns (Feedback[] memory) {
        uint256[] memory feedbackIds = userFeedbackIds[user];
        Feedback[] memory userFeedbacks = new Feedback[](feedbackIds.length);
        
        for (uint256 i = 0; i < feedbackIds.length; i++) {
            userFeedbacks[i] = feedbacks[feedbackIds[i]];
        }
        
        return userFeedbacks;
    }
    
    /**
     * @dev Get the total number of feedbacks
     * @return The total count
     */
    function getTotalFeedbackCount() external view returns (uint256) {
        return feedbacks.length;
    }
    
    /**
     * @dev Get the average rating
     * @return The average rating (scaled by 100 for precision)
     */
    function getAverageRating() external view returns (uint256) {
        if (feedbackCount == 0) {
            return 0;
        }
        return (totalRating * 100) / feedbackCount;
    }
    
    /**
     * @dev Get feedbacks by rating
     * @param rating The rating to filter by (1-5)
     * @return Array of feedbacks with the specified rating
     */
    function getFeedbacksByRating(uint8 rating) external view returns (Feedback[] memory) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        
        // Count feedbacks with the specified rating
        uint256 count = 0;
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (feedbacks[i].rating == rating) {
                count++;
            }
        }
        
        // Create array and populate
        Feedback[] memory filteredFeedbacks = new Feedback[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (feedbacks[i].rating == rating) {
                filteredFeedbacks[index] = feedbacks[i];
                index++;
            }
        }
        
        return filteredFeedbacks;
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
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (feedbacks[i].rating == 1) count1++;
            else if (feedbacks[i].rating == 2) count2++;
            else if (feedbacks[i].rating == 3) count3++;
            else if (feedbacks[i].rating == 4) count4++;
            else if (feedbacks[i].rating == 5) count5++;
        }
        
        return (count1, count2, count3, count4, count5);
    }
    
    /**
     * @dev Get the latest N feedbacks
     * @param count Number of feedbacks to retrieve
     * @return Array of the latest feedbacks
     */
    function getLatestFeedbacks(uint256 count) external view returns (Feedback[] memory) {
        if (count > feedbacks.length) {
            count = feedbacks.length;
        }
        
        Feedback[] memory latestFeedbacks = new Feedback[](count);
        uint256 startIndex = feedbacks.length - count;
        
        for (uint256 i = 0; i < count; i++) {
            latestFeedbacks[i] = feedbacks[startIndex + i];
        }
        
        return latestFeedbacks;
    }
    
    /**
     * @dev Get feedbacks within a time range
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @return Array of feedbacks within the time range
     */
    function getFeedbacksByTimeRange(uint256 startTime, uint256 endTime) external view returns (Feedback[] memory) {
        require(startTime <= endTime, "Invalid time range");
        
        // Count matching feedbacks
        uint256 count = 0;
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (feedbacks[i].timestamp >= startTime && feedbacks[i].timestamp <= endTime) {
                count++;
            }
        }
        
        // Create array and populate
        Feedback[] memory filteredFeedbacks = new Feedback[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < feedbacks.length; i++) {
            if (feedbacks[i].timestamp >= startTime && feedbacks[i].timestamp <= endTime) {
                filteredFeedbacks[index] = feedbacks[i];
                index++;
            }
        }
        
        return filteredFeedbacks;
    }
    
    /**
     * @dev Get statistics
     * @return totalFeedbacks Total number of feedbacks
     * @return averageRating Average rating (scaled by 100)
     * @return _totalRating Sum of all ratings
     */
    function getStats() external view returns (
        uint256 totalFeedbacks,
        uint256 averageRating,
        uint256 _totalRating
    ) {
        uint256 avgRating = 0;
        if (feedbackCount > 0) {
            avgRating = (totalRating * 100) / feedbackCount;
        }
        
        return (feedbacks.length, avgRating, totalRating);
    }
}
