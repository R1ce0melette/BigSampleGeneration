// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TaskRewardSystem
 * @dev A simple task reward system where users complete tasks to earn ETH rewards
 */
contract TaskRewardSystem {
    enum TaskStatus {
        OPEN,
        ASSIGNED,
        COMPLETED,
        VERIFIED,
        CANCELLED
    }
    
    struct Task {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 reward;
        address assignee;
        TaskStatus status;
        uint256 createdAt;
        uint256 completedAt;
        uint256 verifiedAt;
        bool rewardClaimed;
    }
    
    struct UserStats {
        uint256 tasksCreated;
        uint256 tasksCompleted;
        uint256 totalEarned;
        uint256 totalSpent;
    }
    
    uint256 private taskCounter;
    mapping(uint256 => Task) public tasks;
    mapping(address => UserStats) public userStats;
    mapping(address => uint256[]) private createdTasks;
    mapping(address => uint256[]) private assignedTasks;
    
    address public owner;
    uint256 public platformFeePercentage;
    uint256 public constant FEE_DENOMINATOR = 100;
    uint256 public totalFeesCollected;
    
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        string title,
        uint256 reward
    );
    
    event TaskAssigned(
        uint256 indexed taskId,
        address indexed assignee,
        uint256 timestamp
    );
    
    event TaskCompleted(
        uint256 indexed taskId,
        address indexed assignee,
        uint256 timestamp
    );
    
    event TaskVerified(
        uint256 indexed taskId,
        address indexed creator,
        uint256 timestamp
    );
    
    event RewardClaimed(
        uint256 indexed taskId,
        address indexed assignee,
        uint256 amount,
        uint256 fee
    );
    
    event TaskCancelled(
        uint256 indexed taskId,
        address indexed creator
    );
    
    event RefundIssued(
        uint256 indexed taskId,
        address indexed creator,
        uint256 amount
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier taskExists(uint256 taskId) {
        require(taskId > 0 && taskId <= taskCounter, "Task does not exist");
        _;
    }
    
    modifier onlyTaskCreator(uint256 taskId) {
        require(tasks[taskId].creator == msg.sender, "Only task creator can perform this action");
        _;
    }
    
    modifier onlyAssignee(uint256 taskId) {
        require(tasks[taskId].assignee == msg.sender, "Only assignee can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        platformFeePercentage = 5; // 5% platform fee
    }
    
    /**
     * @dev Create a new task with reward
     * @param title Task title
     * @param description Task description
     * @return taskId The ID of the created task
     */
    function createTask(string memory title, string memory description) external payable returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(msg.value > 0, "Reward must be greater than 0");
        
        taskCounter++;
        uint256 taskId = taskCounter;
        
        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            title: title,
            description: description,
            reward: msg.value,
            assignee: address(0),
            status: TaskStatus.OPEN,
            createdAt: block.timestamp,
            completedAt: 0,
            verifiedAt: 0,
            rewardClaimed: false
        });
        
        createdTasks[msg.sender].push(taskId);
        userStats[msg.sender].tasksCreated++;
        userStats[msg.sender].totalSpent += msg.value;
        
        emit TaskCreated(taskId, msg.sender, title, msg.value);
        
        return taskId;
    }
    
    /**
     * @dev Assign a task to yourself
     * @param taskId The ID of the task
     */
    function assignTask(uint256 taskId) external taskExists(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.OPEN, "Task not available");
        require(task.creator != msg.sender, "Cannot assign own task");
        
        task.assignee = msg.sender;
        task.status = TaskStatus.ASSIGNED;
        
        assignedTasks[msg.sender].push(taskId);
        
        emit TaskAssigned(taskId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Mark task as completed by assignee
     * @param taskId The ID of the task
     */
    function completeTask(uint256 taskId) 
        external 
        taskExists(taskId) 
        onlyAssignee(taskId) 
    {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.ASSIGNED, "Task not assigned");
        
        task.status = TaskStatus.COMPLETED;
        task.completedAt = block.timestamp;
        
        emit TaskCompleted(taskId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Verify task completion and release reward
     * @param taskId The ID of the task
     */
    function verifyTask(uint256 taskId) 
        external 
        taskExists(taskId) 
        onlyTaskCreator(taskId) 
    {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.COMPLETED, "Task not completed");
        
        task.status = TaskStatus.VERIFIED;
        task.verifiedAt = block.timestamp;
        
        emit TaskVerified(taskId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Claim reward for verified task
     * @param taskId The ID of the task
     */
    function claimReward(uint256 taskId) 
        external 
        taskExists(taskId) 
        onlyAssignee(taskId) 
    {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.VERIFIED, "Task not verified");
        require(!task.rewardClaimed, "Reward already claimed");
        
        task.rewardClaimed = true;
        
        // Calculate platform fee
        uint256 fee = (task.reward * platformFeePercentage) / FEE_DENOMINATOR;
        uint256 netReward = task.reward - fee;
        
        totalFeesCollected += fee;
        userStats[task.assignee].tasksCompleted++;
        userStats[task.assignee].totalEarned += netReward;
        
        // Transfer reward to assignee
        (bool success, ) = task.assignee.call{value: netReward}("");
        require(success, "Reward transfer failed");
        
        emit RewardClaimed(taskId, task.assignee, netReward, fee);
    }
    
    /**
     * @dev Cancel a task and refund creator
     * @param taskId The ID of the task
     */
    function cancelTask(uint256 taskId) 
        external 
        taskExists(taskId) 
        onlyTaskCreator(taskId) 
    {
        Task storage task = tasks[taskId];
        
        require(
            task.status == TaskStatus.OPEN || task.status == TaskStatus.ASSIGNED,
            "Cannot cancel completed or verified task"
        );
        
        task.status = TaskStatus.CANCELLED;
        
        // Refund the creator
        uint256 refundAmount = task.reward;
        
        (bool success, ) = task.creator.call{value: refundAmount}("");
        require(success, "Refund transfer failed");
        
        emit TaskCancelled(taskId, msg.sender);
        emit RefundIssued(taskId, msg.sender, refundAmount);
    }
    
    /**
     * @dev Unassign from a task (only if assigned but not completed)
     * @param taskId The ID of the task
     */
    function unassignTask(uint256 taskId) 
        external 
        taskExists(taskId) 
        onlyAssignee(taskId) 
    {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.ASSIGNED, "Task not in assigned state");
        
        task.assignee = address(0);
        task.status = TaskStatus.OPEN;
    }
    
    /**
     * @dev Update platform fee percentage (owner only)
     * @param newFeePercentage The new fee percentage
     */
    function updatePlatformFee(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 20, "Fee cannot exceed 20%");
        platformFeePercentage = newFeePercentage;
    }
    
    /**
     * @dev Withdraw platform fees (owner only)
     * @param amount The amount to withdraw
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= totalFeesCollected, "Insufficient fees collected");
        
        totalFeesCollected -= amount;
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }
    
    /**
     * @dev Get task details
     * @param taskId The ID of the task
     * @return id Task ID
     * @return creator Creator address
     * @return title Task title
     * @return description Task description
     * @return reward Reward amount
     * @return assignee Assignee address
     * @return status Task status
     * @return createdAt Creation timestamp
     * @return completedAt Completion timestamp
     * @return verifiedAt Verification timestamp
     * @return rewardClaimed Whether reward has been claimed
     */
    function getTaskDetails(uint256 taskId) 
        external 
        view 
        taskExists(taskId) 
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256 reward,
            address assignee,
            TaskStatus status,
            uint256 createdAt,
            uint256 completedAt,
            uint256 verifiedAt,
            bool rewardClaimed
        ) 
    {
        Task memory task = tasks[taskId];
        return (
            task.id,
            task.creator,
            task.title,
            task.description,
            task.reward,
            task.assignee,
            task.status,
            task.createdAt,
            task.completedAt,
            task.verifiedAt,
            task.rewardClaimed
        );
    }
    
    /**
     * @dev Get user statistics
     * @param user The user's address
     * @return tasksCreated Number of tasks created
     * @return tasksCompleted Number of tasks completed
     * @return totalEarned Total ETH earned
     * @return totalSpent Total ETH spent
     */
    function getUserStats(address user) external view returns (
        uint256 tasksCreated,
        uint256 tasksCompleted,
        uint256 totalEarned,
        uint256 totalSpent
    ) {
        UserStats memory stats = userStats[user];
        return (
            stats.tasksCreated,
            stats.tasksCompleted,
            stats.totalEarned,
            stats.totalSpent
        );
    }
    
    /**
     * @dev Get tasks created by a user
     * @param creator The creator's address
     * @return Array of task IDs
     */
    function getTasksByCreator(address creator) external view returns (uint256[] memory) {
        return createdTasks[creator];
    }
    
    /**
     * @dev Get tasks assigned to a user
     * @param assignee The assignee's address
     * @return Array of task IDs
     */
    function getTasksByAssignee(address assignee) external view returns (uint256[] memory) {
        return assignedTasks[assignee];
    }
    
    /**
     * @dev Get all open tasks
     * @return Array of open task IDs
     */
    function getOpenTasks() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        // Count open tasks
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory openTasks = new uint256[](openCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openTasks[index] = i;
                index++;
            }
        }
        
        return openTasks;
    }
    
    /**
     * @dev Get all completed tasks
     * @return Array of completed task IDs
     */
    function getCompletedTasks() external view returns (uint256[] memory) {
        uint256 completedCount = 0;
        
        // Count completed tasks
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.COMPLETED) {
                completedCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory completedTasks = new uint256[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.COMPLETED) {
                completedTasks[index] = i;
                index++;
            }
        }
        
        return completedTasks;
    }
    
    /**
     * @dev Get all verified tasks
     * @return Array of verified task IDs
     */
    function getVerifiedTasks() external view returns (uint256[] memory) {
        uint256 verifiedCount = 0;
        
        // Count verified tasks
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.VERIFIED) {
                verifiedCount++;
            }
        }
        
        // Create array and populate
        uint256[] memory verifiedTasks = new uint256[](verifiedCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == TaskStatus.VERIFIED) {
                verifiedTasks[index] = i;
                index++;
            }
        }
        
        return verifiedTasks;
    }
    
    /**
     * @dev Calculate net reward after platform fee
     * @param reward The gross reward amount
     * @return netReward The reward after fee deduction
     * @return fee The platform fee
     */
    function calculateNetReward(uint256 reward) external view returns (uint256 netReward, uint256 fee) {
        fee = (reward * platformFeePercentage) / FEE_DENOMINATOR;
        netReward = reward - fee;
        return (netReward, fee);
    }
    
    /**
     * @dev Get total number of tasks
     * @return The total count
     */
    function getTotalTasks() external view returns (uint256) {
        return taskCounter;
    }
    
    /**
     * @dev Get total rewards available (locked in tasks)
     * @return The total amount
     */
    function getTotalRewardsLocked() external view returns (uint256) {
        uint256 total = 0;
        
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status != TaskStatus.CANCELLED && !tasks[i].rewardClaimed) {
                total += tasks[i].reward;
            }
        }
        
        return total;
    }
    
    /**
     * @dev Check if a task can be assigned
     * @param taskId The ID of the task
     * @return Whether the task can be assigned
     */
    function canAssignTask(uint256 taskId) external view returns (bool) {
        if (taskId == 0 || taskId > taskCounter) {
            return false;
        }
        return tasks[taskId].status == TaskStatus.OPEN;
    }
    
    /**
     * @dev Check if a task can be completed
     * @param taskId The ID of the task
     * @param user The user's address
     * @return Whether the task can be completed by the user
     */
    function canCompleteTask(uint256 taskId, address user) external view returns (bool) {
        if (taskId == 0 || taskId > taskCounter) {
            return false;
        }
        Task memory task = tasks[taskId];
        return task.status == TaskStatus.ASSIGNED && task.assignee == user;
    }
}
