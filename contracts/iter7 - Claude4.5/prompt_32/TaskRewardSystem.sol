// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TaskRewardSystem
 * @dev Simple task reward system where users complete tasks to earn ETH rewards
 */
contract TaskRewardSystem {
    // Task status enumeration
    enum TaskStatus { OPEN, CLAIMED, COMPLETED, CANCELLED }

    // Task structure
    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        address assignedTo;
        TaskStatus status;
        uint256 createdAt;
        uint256 claimedAt;
        uint256 completedAt;
        bool exists;
    }

    // Task completion record
    struct CompletionRecord {
        uint256 taskId;
        address user;
        uint256 reward;
        uint256 timestamp;
    }

    // State variables
    address public owner;
    uint256 private taskIdCounter;
    
    // Mappings
    mapping(uint256 => Task) private tasks;
    mapping(address => uint256[]) private creatorTasks;
    mapping(address => uint256[]) private userClaimedTasks;
    mapping(address => uint256[]) private userCompletedTasks;
    mapping(address => uint256) private userTotalEarnings;
    mapping(address => CompletionRecord[]) private userCompletionHistory;

    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward, uint256 timestamp);
    event TaskClaimed(uint256 indexed taskId, address indexed user, uint256 timestamp);
    event TaskCompleted(uint256 indexed taskId, address indexed user, uint256 reward, uint256 timestamp);
    event TaskCancelled(uint256 indexed taskId, address indexed creator, uint256 timestamp);
    event RewardPaid(uint256 indexed taskId, address indexed user, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier taskExists(uint256 taskId) {
        require(tasks[taskId].exists, "Task does not exist");
        _;
    }

    modifier onlyTaskCreator(uint256 taskId) {
        require(tasks[taskId].creator == msg.sender, "Not task creator");
        _;
    }

    modifier taskOpen(uint256 taskId) {
        require(tasks[taskId].status == TaskStatus.OPEN, "Task is not open");
        _;
    }

    modifier taskClaimed(uint256 taskId) {
        require(tasks[taskId].status == TaskStatus.CLAIMED, "Task is not claimed");
        _;
    }

    constructor() {
        owner = msg.sender;
        taskIdCounter = 1;
    }

    /**
     * @dev Create a new task with reward
     * @param title Task title
     * @param description Task description
     * @param reward Reward amount in wei
     * @return taskId ID of created task
     */
    function createTask(
        string memory title,
        string memory description,
        uint256 reward
    ) public payable returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(reward > 0, "Reward must be greater than 0");
        require(msg.value == reward, "Must send exact reward amount");

        uint256 taskId = taskIdCounter;
        taskIdCounter++;

        tasks[taskId] = Task({
            taskId: taskId,
            creator: msg.sender,
            title: title,
            description: description,
            reward: reward,
            assignedTo: address(0),
            status: TaskStatus.OPEN,
            createdAt: block.timestamp,
            claimedAt: 0,
            completedAt: 0,
            exists: true
        });

        creatorTasks[msg.sender].push(taskId);

        emit TaskCreated(taskId, msg.sender, title, reward, block.timestamp);

        return taskId;
    }

    /**
     * @dev Claim a task to work on it
     * @param taskId Task ID to claim
     */
    function claimTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        taskOpen(taskId) 
    {
        Task storage task = tasks[taskId];
        require(task.creator != msg.sender, "Creator cannot claim own task");

        task.status = TaskStatus.CLAIMED;
        task.assignedTo = msg.sender;
        task.claimedAt = block.timestamp;

        userClaimedTasks[msg.sender].push(taskId);

        emit TaskClaimed(taskId, msg.sender, block.timestamp);
    }

    /**
     * @dev Mark task as completed and pay reward (only creator can mark complete)
     * @param taskId Task ID to complete
     */
    function completeTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        taskClaimed(taskId) 
        onlyTaskCreator(taskId) 
    {
        Task storage task = tasks[taskId];
        
        task.status = TaskStatus.COMPLETED;
        task.completedAt = block.timestamp;

        address worker = task.assignedTo;
        uint256 reward = task.reward;

        // Update user earnings
        userTotalEarnings[worker] += reward;
        userCompletedTasks[worker].push(taskId);

        // Record completion
        userCompletionHistory[worker].push(CompletionRecord({
            taskId: taskId,
            user: worker,
            reward: reward,
            timestamp: block.timestamp
        }));

        // Transfer reward to worker
        payable(worker).transfer(reward);

        emit TaskCompleted(taskId, worker, reward, block.timestamp);
        emit RewardPaid(taskId, worker, reward);
    }

    /**
     * @dev Cancel a task and refund creator (only if not claimed)
     * @param taskId Task ID to cancel
     */
    function cancelTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        taskOpen(taskId) 
        onlyTaskCreator(taskId) 
    {
        Task storage task = tasks[taskId];
        
        task.status = TaskStatus.CANCELLED;

        // Refund creator
        payable(task.creator).transfer(task.reward);

        emit TaskCancelled(taskId, msg.sender, block.timestamp);
    }

    /**
     * @dev Unclaim a task (worker gives up the task)
     * @param taskId Task ID to unclaim
     */
    function unclaimTask(uint256 taskId) 
        public 
        taskExists(taskId) 
        taskClaimed(taskId) 
    {
        Task storage task = tasks[taskId];
        require(task.assignedTo == msg.sender, "Not assigned to you");

        task.status = TaskStatus.OPEN;
        task.assignedTo = address(0);
        task.claimedAt = 0;

        emit TaskClaimed(taskId, address(0), block.timestamp);
    }

    /**
     * @dev Batch create multiple tasks
     * @param titles Array of task titles
     * @param descriptions Array of task descriptions
     * @param rewards Array of reward amounts
     * @return Array of created task IDs
     */
    function batchCreateTasks(
        string[] memory titles,
        string[] memory descriptions,
        uint256[] memory rewards
    ) public payable returns (uint256[] memory) {
        require(titles.length == descriptions.length && titles.length == rewards.length, "Array length mismatch");
        require(titles.length > 0, "Empty arrays");

        uint256 totalReward = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            totalReward += rewards[i];
        }
        require(msg.value == totalReward, "Incorrect total reward amount");

        uint256[] memory taskIds = new uint256[](titles.length);

        for (uint256 i = 0; i < titles.length; i++) {
            require(bytes(titles[i]).length > 0, "Title cannot be empty");
            require(rewards[i] > 0, "Reward must be greater than 0");

            uint256 taskId = taskIdCounter;
            taskIdCounter++;

            tasks[taskId] = Task({
                taskId: taskId,
                creator: msg.sender,
                title: titles[i],
                description: descriptions[i],
                reward: rewards[i],
                assignedTo: address(0),
                status: TaskStatus.OPEN,
                createdAt: block.timestamp,
                claimedAt: 0,
                completedAt: 0,
                exists: true
            });

            creatorTasks[msg.sender].push(taskId);
            taskIds[i] = taskId;

            emit TaskCreated(taskId, msg.sender, titles[i], rewards[i], block.timestamp);
        }

        return taskIds;
    }

    /**
     * @dev Deposit funds to contract (for future rewards)
     */
    function depositFunds() public payable {
        require(msg.value > 0, "Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    // View Functions

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
     * @dev Get task basic info
     * @param taskId Task ID
     * @return title Task title
     * @return reward Reward amount
     * @return status Task status
     * @return assignedTo Assigned worker address
     */
    function getTaskInfo(uint256 taskId) 
        public 
        view 
        taskExists(taskId) 
        returns (
            string memory title,
            uint256 reward,
            TaskStatus status,
            address assignedTo
        ) 
    {
        Task memory task = tasks[taskId];
        return (task.title, task.reward, task.status, task.assignedTo);
    }

    /**
     * @dev Get all open tasks
     * @return Array of open task IDs
     */
    function getOpenTasks() public view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        for (uint256 i = 1; i < taskIdCounter; i++) {
            if (tasks[i].exists && tasks[i].status == TaskStatus.OPEN) {
                openCount++;
            }
        }

        uint256[] memory openTasks = new uint256[](openCount);
        uint256 index = 0;
        for (uint256 i = 1; i < taskIdCounter; i++) {
            if (tasks[i].exists && tasks[i].status == TaskStatus.OPEN) {
                openTasks[index] = i;
                index++;
            }
        }

        return openTasks;
    }

    /**
     * @dev Get tasks created by a user
     * @param creator Creator address
     * @return Array of task IDs
     */
    function getTasksByCreator(address creator) public view returns (uint256[] memory) {
        return creatorTasks[creator];
    }

    /**
     * @dev Get tasks claimed by a user
     * @param user User address
     * @return Array of task IDs
     */
    function getTasksClaimedByUser(address user) public view returns (uint256[] memory) {
        return userClaimedTasks[user];
    }

    /**
     * @dev Get tasks completed by a user
     * @param user User address
     * @return Array of task IDs
     */
    function getTasksCompletedByUser(address user) public view returns (uint256[] memory) {
        return userCompletedTasks[user];
    }

    /**
     * @dev Get active tasks for a user (claimed but not completed)
     * @param user User address
     * @return Array of active task IDs
     */
    function getActiveTasksForUser(address user) public view returns (uint256[] memory) {
        uint256[] memory claimedTasks = userClaimedTasks[user];
        uint256 activeCount = 0;

        for (uint256 i = 0; i < claimedTasks.length; i++) {
            if (tasks[claimedTasks[i]].status == TaskStatus.CLAIMED) {
                activeCount++;
            }
        }

        uint256[] memory activeTasks = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < claimedTasks.length; i++) {
            if (tasks[claimedTasks[i]].status == TaskStatus.CLAIMED) {
                activeTasks[index] = claimedTasks[i];
                index++;
            }
        }

        return activeTasks;
    }

    /**
     * @dev Get total earnings for a user
     * @param user User address
     * @return Total ETH earned
     */
    function getUserEarnings(address user) public view returns (uint256) {
        return userTotalEarnings[user];
    }

    /**
     * @dev Get user completion history
     * @param user User address
     * @return Array of completion records
     */
    function getUserCompletionHistory(address user) public view returns (CompletionRecord[] memory) {
        return userCompletionHistory[user];
    }

    /**
     * @dev Get user statistics
     * @param user User address
     * @return tasksCreated Number of tasks created
     * @return tasksClaimed Number of tasks claimed
     * @return tasksCompleted Number of tasks completed
     * @return totalEarnings Total earnings
     */
    function getUserStats(address user) 
        public 
        view 
        returns (
            uint256 tasksCreated,
            uint256 tasksClaimed,
            uint256 tasksCompleted,
            uint256 totalEarnings
        ) 
    {
        return (
            creatorTasks[user].length,
            userClaimedTasks[user].length,
            userCompletedTasks[user].length,
            userTotalEarnings[user]
        );
    }

    /**
     * @dev Get total number of tasks
     * @return Total task count
     */
    function getTotalTasks() public view returns (uint256) {
        return taskIdCounter - 1;
    }

    /**
     * @dev Get contract balance
     * @return Contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get tasks by status
     * @param status Task status to filter
     * @return Array of task IDs
     */
    function getTasksByStatus(TaskStatus status) public view returns (uint256[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 1; i < taskIdCounter; i++) {
            if (tasks[i].exists && tasks[i].status == status) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < taskIdCounter; i++) {
            if (tasks[i].exists && tasks[i].status == status) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    /**
     * @dev Get total rewards available in contract
     * @return Total locked rewards
     */
    function getTotalLockedRewards() public view returns (uint256) {
        uint256 totalLocked = 0;
        
        for (uint256 i = 1; i < taskIdCounter; i++) {
            if (tasks[i].exists && 
                (tasks[i].status == TaskStatus.OPEN || tasks[i].status == TaskStatus.CLAIMED)) {
                totalLocked += tasks[i].reward;
            }
        }

        return totalLocked;
    }

    /**
     * @dev Get top earners
     * @param n Number of top earners to return
     * @return addresses Array of addresses
     * @return earnings Array of earnings
     */
    function getTopEarners(uint256 n) public view returns (address[] memory addresses, uint256[] memory earnings) {
        // Collect all users with earnings
        address[] memory allEarners = new address[](taskIdCounter);
        uint256 earnerCount = 0;

        for (uint256 i = 1; i < taskIdCounter; i++) {
            if (tasks[i].exists && tasks[i].status == TaskStatus.COMPLETED) {
                address earner = tasks[i].assignedTo;
                bool found = false;
                for (uint256 j = 0; j < earnerCount; j++) {
                    if (allEarners[j] == earner) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    allEarners[earnerCount] = earner;
                    earnerCount++;
                }
            }
        }

        if (n > earnerCount) {
            n = earnerCount;
        }

        addresses = new address[](n);
        earnings = new uint256[](n);

        // Simple selection sort for top N
        for (uint256 i = 0; i < n; i++) {
            uint256 maxEarnings = 0;
            uint256 maxIndex = 0;

            for (uint256 j = 0; j < earnerCount; j++) {
                bool alreadySelected = false;
                for (uint256 k = 0; k < i; k++) {
                    if (addresses[k] == allEarners[j]) {
                        alreadySelected = true;
                        break;
                    }
                }

                if (!alreadySelected && userTotalEarnings[allEarners[j]] > maxEarnings) {
                    maxEarnings = userTotalEarnings[allEarners[j]];
                    maxIndex = j;
                }
            }

            if (maxEarnings > 0) {
                addresses[i] = allEarners[maxIndex];
                earnings[i] = maxEarnings;
            }
        }

        return (addresses, earnings);
    }

    /**
     * @dev Check if task is open
     * @param taskId Task ID
     * @return true if open
     */
    function isTaskOpen(uint256 taskId) public view taskExists(taskId) returns (bool) {
        return tasks[taskId].status == TaskStatus.OPEN;
    }

    /**
     * @dev Check if task is claimed
     * @param taskId Task ID
     * @return true if claimed
     */
    function isTaskClaimed(uint256 taskId) public view taskExists(taskId) returns (bool) {
        return tasks[taskId].status == TaskStatus.CLAIMED;
    }

    /**
     * @dev Check if task is completed
     * @param taskId Task ID
     * @return true if completed
     */
    function isTaskCompleted(uint256 taskId) public view taskExists(taskId) returns (bool) {
        return tasks[taskId].status == TaskStatus.COMPLETED;
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
