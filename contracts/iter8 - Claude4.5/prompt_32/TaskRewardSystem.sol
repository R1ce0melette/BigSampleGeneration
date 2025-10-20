// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TaskRewardSystem
 * @dev Contract that implements a simple task reward system where users complete tasks to earn ETH rewards
 */
contract TaskRewardSystem {
    // Task status enum
    enum TaskStatus {
        Open,
        InProgress,
        Completed,
        Verified,
        Cancelled
    }

    // Task structure
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

    // User statistics
    struct UserStats {
        uint256 tasksCreated;
        uint256 tasksCompleted;
        uint256 tasksVerified;
        uint256 totalRewardsEarned;
        uint256 totalRewardsPaid;
        uint256 totalRewardsClaimed;
    }

    // State variables
    address public owner;
    uint256 private taskCounter;

    mapping(uint256 => Task) private tasks;
    mapping(address => uint256[]) private creatorTasks;
    mapping(address => uint256[]) private assigneeTasks;
    mapping(address => UserStats) private userStats;
    mapping(address => uint256) private pendingRewards;

    uint256[] private allTaskIds;

    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskStarted(uint256 indexed taskId, address indexed assignee);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee);
    event TaskVerified(uint256 indexed taskId, address indexed verifier);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event RewardClaimed(uint256 indexed taskId, address indexed assignee, uint256 amount);
    event RewardWithdrawn(address indexed user, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier taskExists(uint256 taskId) {
        require(taskId > 0 && taskId <= taskCounter, "Task does not exist");
        _;
    }

    modifier onlyCreator(uint256 taskId) {
        require(tasks[taskId].creator == msg.sender, "Not the task creator");
        _;
    }

    modifier onlyAssignee(uint256 taskId) {
        require(tasks[taskId].assignee == msg.sender, "Not the task assignee");
        _;
    }

    modifier taskIsOpen(uint256 taskId) {
        require(tasks[taskId].status == TaskStatus.Open, "Task is not open");
        _;
    }

    modifier taskInProgress(uint256 taskId) {
        require(tasks[taskId].status == TaskStatus.InProgress, "Task is not in progress");
        _;
    }

    modifier taskCompleted(uint256 taskId) {
        require(tasks[taskId].status == TaskStatus.Completed, "Task is not completed");
        _;
    }

    constructor() {
        owner = msg.sender;
        taskCounter = 0;
    }

    /**
     * @dev Create a new task with reward
     * @param title Task title
     * @param description Task description
     * @return taskId ID of the created task
     */
    function createTask(string memory title, string memory description) public payable returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(msg.value > 0, "Reward must be greater than 0");

        taskCounter++;
        uint256 taskId = taskCounter;

        Task storage newTask = tasks[taskId];
        newTask.id = taskId;
        newTask.creator = msg.sender;
        newTask.title = title;
        newTask.description = description;
        newTask.reward = msg.value;
        newTask.assignee = address(0);
        newTask.status = TaskStatus.Open;
        newTask.createdAt = block.timestamp;
        newTask.completedAt = 0;
        newTask.verifiedAt = 0;
        newTask.rewardClaimed = false;

        creatorTasks[msg.sender].push(taskId);
        allTaskIds.push(taskId);

        // Update statistics
        userStats[msg.sender].tasksCreated++;

        emit TaskCreated(taskId, msg.sender, title, msg.value);

        return taskId;
    }

    /**
     * @dev Assign task to a user
     * @param taskId Task ID
     * @param assignee User address to assign
     */
    function assignTask(uint256 taskId, address assignee) 
        public 
        taskExists(taskId) 
        onlyCreator(taskId) 
        taskIsOpen(taskId) 
    {
        require(assignee != address(0), "Invalid assignee address");
        require(assignee != msg.sender, "Cannot assign to yourself");

        tasks[taskId].assignee = assignee;
        tasks[taskId].status = TaskStatus.InProgress;
        assigneeTasks[assignee].push(taskId);

        emit TaskAssigned(taskId, assignee);
        emit TaskStarted(taskId, assignee);
    }

    /**
     * @dev Start working on an open task (self-assignment)
     * @param taskId Task ID
     */
    function startTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        taskIsOpen(taskId) 
    {
        require(msg.sender != tasks[taskId].creator, "Creator cannot work on their own task");

        tasks[taskId].assignee = msg.sender;
        tasks[taskId].status = TaskStatus.InProgress;
        assigneeTasks[msg.sender].push(taskId);

        emit TaskAssigned(taskId, msg.sender);
        emit TaskStarted(taskId, msg.sender);
    }

    /**
     * @dev Mark task as completed
     * @param taskId Task ID
     */
    function completeTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        onlyAssignee(taskId) 
        taskInProgress(taskId) 
    {
        tasks[taskId].status = TaskStatus.Completed;
        tasks[taskId].completedAt = block.timestamp;

        emit TaskCompleted(taskId, msg.sender);
    }

    /**
     * @dev Verify completed task and release reward
     * @param taskId Task ID
     */
    function verifyTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        onlyCreator(taskId) 
        taskCompleted(taskId) 
    {
        Task storage task = tasks[taskId];
        
        task.status = TaskStatus.Verified;
        task.verifiedAt = block.timestamp;

        // Add reward to assignee's pending rewards
        pendingRewards[task.assignee] += task.reward;

        // Update statistics
        userStats[task.assignee].tasksCompleted++;
        userStats[task.assignee].totalRewardsEarned += task.reward;
        userStats[task.creator].tasksVerified++;
        userStats[task.creator].totalRewardsPaid += task.reward;

        emit TaskVerified(taskId, msg.sender);
    }

    /**
     * @dev Claim reward for verified task
     * @param taskId Task ID
     */
    function claimReward(uint256 taskId) 
        public 
        taskExists(taskId) 
        onlyAssignee(taskId) 
    {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Verified, "Task is not verified");
        require(!task.rewardClaimed, "Reward already claimed");

        task.rewardClaimed = true;
        
        uint256 rewardAmount = task.reward;
        require(pendingRewards[msg.sender] >= rewardAmount, "Insufficient pending rewards");
        
        pendingRewards[msg.sender] -= rewardAmount;
        
        // Update statistics
        userStats[msg.sender].totalRewardsClaimed += rewardAmount;

        payable(msg.sender).transfer(rewardAmount);

        emit RewardClaimed(taskId, msg.sender, rewardAmount);
    }

    /**
     * @dev Withdraw all pending rewards
     */
    function withdrawRewards() public {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards");

        pendingRewards[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit RewardWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Cancel a task and refund reward
     * @param taskId Task ID
     */
    function cancelTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        onlyCreator(taskId) 
    {
        Task storage task = tasks[taskId];
        require(
            task.status == TaskStatus.Open || task.status == TaskStatus.InProgress,
            "Cannot cancel task in current status"
        );

        task.status = TaskStatus.Cancelled;

        // Refund reward to creator
        payable(task.creator).transfer(task.reward);

        emit TaskCancelled(taskId, msg.sender);
    }

    /**
     * @dev Get task details
     * @param taskId Task ID
     * @return Task details
     */
    function getTask(uint256 taskId) 
        public 
        view 
        taskExists(taskId) 
        returns (Task memory) 
    {
        return tasks[taskId];
    }

    /**
     * @dev Get tasks created by user
     * @param creator Creator address
     * @return Array of task IDs
     */
    function getCreatorTasks(address creator) public view returns (uint256[] memory) {
        return creatorTasks[creator];
    }

    /**
     * @dev Get tasks assigned to user
     * @param assignee Assignee address
     * @return Array of task IDs
     */
    function getAssigneeTasks(address assignee) public view returns (uint256[] memory) {
        return assigneeTasks[assignee];
    }

    /**
     * @dev Get all tasks
     * @return Array of all tasks
     */
    function getAllTasks() public view returns (Task[] memory) {
        Task[] memory allTasks = new Task[](allTaskIds.length);
        
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            allTasks[i] = tasks[allTaskIds[i]];
        }
        
        return allTasks;
    }

    /**
     * @dev Get open tasks
     * @return Array of open tasks
     */
    function getOpenTasks() public view returns (Task[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].status == TaskStatus.Open) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status == TaskStatus.Open) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get in-progress tasks
     * @return Array of in-progress tasks
     */
    function getInProgressTasks() public view returns (Task[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].status == TaskStatus.InProgress) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status == TaskStatus.InProgress) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get completed tasks
     * @return Array of completed tasks
     */
    function getCompletedTasks() public view returns (Task[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].status == TaskStatus.Completed) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status == TaskStatus.Completed) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get verified tasks
     * @return Array of verified tasks
     */
    function getVerifiedTasks() public view returns (Task[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].status == TaskStatus.Verified) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status == TaskStatus.Verified) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get tasks by status
     * @param status Task status
     * @return Array of tasks with specified status
     */
    function getTasksByStatus(TaskStatus status) public view returns (Task[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            if (tasks[allTaskIds[i]].status == status) {
                count++;
            }
        }

        Task[] memory result = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status == status) {
                result[index] = task;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return UserStats details
     */
    function getUserStats(address user) public view returns (UserStats memory) {
        return userStats[user];
    }

    /**
     * @dev Get pending rewards for user
     * @param user User address
     * @return Pending reward amount
     */
    function getPendingRewards(address user) public view returns (uint256) {
        return pendingRewards[user];
    }

    /**
     * @dev Get total task count
     * @return Total number of tasks
     */
    function getTotalTaskCount() public view returns (uint256) {
        return taskCounter;
    }

    /**
     * @dev Get total rewards in system
     * @return Total reward amount
     */
    function getTotalRewards() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status != TaskStatus.Cancelled) {
                total += task.reward;
            }
        }
        return total;
    }

    /**
     * @dev Get total unclaimed rewards
     * @return Total unclaimed reward amount
     */
    function getTotalUnclaimedRewards() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < allTaskIds.length; i++) {
            Task memory task = tasks[allTaskIds[i]];
            if (task.status == TaskStatus.Verified && !task.rewardClaimed) {
                total += task.reward;
            }
        }
        return total;
    }

    /**
     * @dev Get top earners
     * @param count Number of top earners to return
     * @return Array of addresses
     */
    function getTopEarners(uint256 count) public view returns (address[] memory) {
        require(count > 0, "Count must be greater than 0");
        
        // Get all users who have earned rewards
        address[] memory earners = new address[](allTaskIds.length);
        mapping(address => bool) storage seen;
        uint256 earnerCount = 0;

        for (uint256 i = 0; i < allTaskIds.length; i++) {
            address assignee = tasks[allTaskIds[i]].assignee;
            if (assignee != address(0) && userStats[assignee].totalRewardsEarned > 0) {
                bool alreadySeen = false;
                for (uint256 j = 0; j < earnerCount; j++) {
                    if (earners[j] == assignee) {
                        alreadySeen = true;
                        break;
                    }
                }
                if (!alreadySeen) {
                    earners[earnerCount] = assignee;
                    earnerCount++;
                }
            }
        }

        // Create array of actual size
        address[] memory actualEarners = new address[](earnerCount);
        for (uint256 i = 0; i < earnerCount; i++) {
            actualEarners[i] = earners[i];
        }

        // Sort by total rewards earned (bubble sort)
        for (uint256 i = 0; i < actualEarners.length; i++) {
            for (uint256 j = i + 1; j < actualEarners.length; j++) {
                if (userStats[actualEarners[i]].totalRewardsEarned < userStats[actualEarners[j]].totalRewardsEarned) {
                    address temp = actualEarners[i];
                    actualEarners[i] = actualEarners[j];
                    actualEarners[j] = temp;
                }
            }
        }

        // Return top count
        uint256 resultCount = count > earnerCount ? earnerCount : count;
        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = actualEarners[i];
        }

        return result;
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != owner, "Already the owner");
        owner = newOwner;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
