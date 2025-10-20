// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    mapping(address => uint256[]) public userFeedbacks;
    
    uint256 public totalRatings;
    uint256 public sumOfRatings;
    
    // Events
    event FeedbackSubmitted(uint256 indexed feedbackId, address indexed user, uint8 rating, uint256 timestamp);
    event FeedbackUpdated(uint256 indexed feedbackId, uint8 oldRating, uint8 newRating);
    
    /**
     * @dev Submit feedback with rating and comment
     * @param _rating The rating from 1 to 5 stars
     * @param _comment The feedback comment
     */
    function submitFeedback(uint8 _rating, string memory _comment) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_comment).length > 0, "Comment cannot be empty");
        
        feedbackCount++;
        
        feedbacks[feedbackCount] = Feedback({
            id: feedbackCount,
            user: msg.sender,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });
        
        userFeedbacks[msg.sender].push(feedbackCount);
        
        totalRatings++;
        sumOfRatings += _rating;
        
        emit FeedbackSubmitted(feedbackCount, msg.sender, _rating, block.timestamp);
    }
    
    /**
     * @dev Update an existing feedback
     * @param _feedbackId The ID of the feedback to update
     * @param _newRating The new rating
     * @param _newComment The new comment
     */
    function updateFeedback(uint256 _feedbackId, uint8 _newRating, string memory _newComment) external {
        require(_feedbackId > 0 && _feedbackId <= feedbackCount, "Invalid feedback ID");
        require(_newRating >= 1 && _newRating <= 5, "Rating must be between 1 and 5");
        require(bytes(_newComment).length > 0, "Comment cannot be empty");
        
        Feedback storage feedback = feedbacks[_feedbackId];
        
        require(feedback.user == msg.sender, "Only the author can update this feedback");
        
        uint8 oldRating = feedback.rating;
        
        // Update the sum of ratings
        sumOfRatings = sumOfRatings - oldRating + _newRating;
        
        feedback.rating = _newRating;
        feedback.comment = _newComment;
        feedback.timestamp = block.timestamp;
        
        emit FeedbackUpdated(_feedbackId, oldRating, _newRating);
    }
    
    /**
     * @dev Get feedback details
     * @param _feedbackId The ID of the feedback
     * @return id The feedback ID
     * @return user The user who submitted the feedback
     * @return rating The rating
     * @return comment The comment
     * @return timestamp The timestamp
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
     * @dev Get all feedback IDs submitted by a user
     * @param _user The address of the user
     * @return An array of feedback IDs
     */
    function getUserFeedbacks(address _user) external view returns (uint256[] memory) {
        return userFeedbacks[_user];
    }
    
    /**
     * @dev Get the average rating
     * @return The average rating (multiplied by 100 for precision)
     */
    function getAverageRating() external view returns (uint256) {
        if (totalRatings == 0) {
            return 0;
        }
        
        // Return average multiplied by 100 for 2 decimal precision
        // e.g., 450 means 4.50 stars
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
        for (uint256 i = 1; i <= feedbackCount; i++) {
            uint8 rating = feedbacks[i].rating;
            
            if (rating == 1) count1++;
            else if (rating == 2) count2++;
            else if (rating == 3) count3++;
            else if (rating == 4) count4++;
            else if (rating == 5) count5++;
        }
        
        return (count1, count2, count3, count4, count5);
    }
    
    /**
     * @dev Get recent feedback IDs
     * @param _limit Maximum number of feedback IDs to return
     * @return An array of recent feedback IDs (most recent first)
     */
    function getRecentFeedback(uint256 _limit) external view returns (uint256[] memory) {
        uint256 count = feedbackCount < _limit ? feedbackCount : _limit;
        uint256[] memory recentFeedbackIds = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recentFeedbackIds[i] = feedbackCount - i;
        }
        
        return recentFeedbackIds;
    }
    
    /**
     * @dev Get total feedback count
     * @return The total number of feedbacks submitted
     */
    function getTotalFeedbackCount() external view returns (uint256) {
        return feedbackCount;
    }
}
