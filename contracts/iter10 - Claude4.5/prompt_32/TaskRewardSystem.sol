// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskRewardSystem {
    address public owner;

    enum TaskStatus { OPEN, ASSIGNED, COMPLETED, VERIFIED, CANCELLED }

    struct Task {
        uint256 id;
        string title;
        string description;
        uint256 reward;
        address assignee;
        TaskStatus status;
        uint256 createdAt;
        uint256 completedAt;
    }

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks;
    mapping(address => uint256) public userEarnings;

    event TaskCreated(uint256 indexed taskId, string title, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee);
    event TaskVerified(uint256 indexed taskId, address indexed assignee, uint256 reward);
    event TaskCancelled(uint256 indexed taskId);
    event RewardClaimed(address indexed user, uint256 amount);
    event ContractFunded(address indexed funder, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier taskExists(uint256 taskId) {
        require(taskId > 0 && taskId <= taskCount, "Task does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory title, string memory description, uint256 reward) external onlyOwner {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(reward > 0, "Reward must be greater than 0");
        require(address(this).balance >= reward, "Insufficient contract balance for reward");

        taskCount++;

        tasks[taskCount] = Task({
            id: taskCount,
            title: title,
            description: description,
            reward: reward,
            assignee: address(0),
            status: TaskStatus.OPEN,
            createdAt: block.timestamp,
            completedAt: 0
        });

        emit TaskCreated(taskCount, title, reward);
    }

    function assignTask(uint256 taskId) external taskExists(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.OPEN, "Task is not open");
        require(task.assignee == address(0), "Task already assigned");

        task.assignee = msg.sender;
        task.status = TaskStatus.ASSIGNED;
        userTasks[msg.sender].push(taskId);

        emit TaskAssigned(taskId, msg.sender);
    }

    function completeTask(uint256 taskId) external taskExists(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.assignee == msg.sender, "Not assigned to this task");
        require(task.status == TaskStatus.ASSIGNED, "Task is not in assigned status");

        task.status = TaskStatus.COMPLETED;
        task.completedAt = block.timestamp;

        emit TaskCompleted(taskId, msg.sender);
    }

    function verifyAndReward(uint256 taskId) external onlyOwner taskExists(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.status == TaskStatus.COMPLETED, "Task is not completed");
        require(address(this).balance >= task.reward, "Insufficient contract balance");

        task.status = TaskStatus.VERIFIED;
        userEarnings[task.assignee] += task.reward;

        emit TaskVerified(taskId, task.assignee, task.reward);
    }

    function cancelTask(uint256 taskId) external onlyOwner taskExists(taskId) {
        Task storage task = tasks[taskId];
        
        require(task.status != TaskStatus.VERIFIED, "Cannot cancel verified task");

        if (task.status == TaskStatus.ASSIGNED || task.status == TaskStatus.COMPLETED) {
            // Remove from assignee's task list if assigned
            _removeTaskFromUser(task.assignee, taskId);
        }

        task.status = TaskStatus.CANCELLED;

        emit TaskCancelled(taskId);
    }

    function claimReward() external {
        uint256 earnings = userEarnings[msg.sender];
        require(earnings > 0, "No rewards to claim");
        require(address(this).balance >= earnings, "Insufficient contract balance");

        userEarnings[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: earnings}("");
        require(success, "Reward transfer failed");

        emit RewardClaimed(msg.sender, earnings);
    }

    function _removeTaskFromUser(address user, uint256 taskId) private {
        uint256[] storage tasks = userTasks[user];
        
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i] == taskId) {
                tasks[i] = tasks[tasks.length - 1];
                tasks.pop();
                break;
            }
        }
    }

    function getTask(uint256 taskId) external view taskExists(taskId) returns (
        uint256 id,
        string memory title,
        string memory description,
        uint256 reward,
        address assignee,
        TaskStatus status,
        uint256 createdAt,
        uint256 completedAt
    ) {
        Task memory task = tasks[taskId];
        return (
            task.id,
            task.title,
            task.description,
            task.reward,
            task.assignee,
            task.status,
            task.createdAt,
            task.completedAt
        );
    }

    function getUserTasks(address user) external view returns (uint256[] memory) {
        return userTasks[user];
    }

    function getUserEarnings(address user) external view returns (uint256) {
        return userEarnings[user];
    }

    function getOpenTasks() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openCount++;
            }
        }

        uint256[] memory openTaskIds = new uint256[](openCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openTaskIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return openTaskIds;
    }

    function getCompletedTasks() external view returns (uint256[] memory) {
        uint256 completedCount = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.COMPLETED) {
                completedCount++;
            }
        }

        uint256[] memory completedTaskIds = new uint256[](completedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.COMPLETED) {
                completedTaskIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return completedTaskIds;
    }

    function fundContract() external payable onlyOwner {
        require(msg.value > 0, "Must send some ETH");
        emit ContractFunded(msg.sender, msg.value);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit ContractFunded(msg.sender, msg.value);
    }
}
