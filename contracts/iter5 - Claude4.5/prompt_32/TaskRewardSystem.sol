// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskRewardSystem {
    address public owner;
    
    enum TaskStatus { OPEN, CLAIMED, COMPLETED, CANCELLED }
    
    struct Task {
        uint256 id;
        string title;
        string description;
        uint256 reward;
        address creator;
        address assignee;
        TaskStatus status;
        uint256 createdTime;
        uint256 completedTime;
    }
    
    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public creatorTasks;
    mapping(address => uint256[]) public assigneeTasks;
    
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward);
    event TaskClaimed(uint256 indexed taskId, address indexed assignee);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee, uint256 reward);
    event TaskCancelled(uint256 indexed taskId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createTask(string memory _title, string memory _description, uint256 _reward) external payable {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_reward > 0, "Reward must be greater than zero");
        require(msg.value >= _reward, "Insufficient funds for reward");
        
        taskCount++;
        
        tasks[taskCount] = Task({
            id: taskCount,
            title: _title,
            description: _description,
            reward: _reward,
            creator: msg.sender,
            assignee: address(0),
            status: TaskStatus.OPEN,
            createdTime: block.timestamp,
            completedTime: 0
        });
        
        creatorTasks[msg.sender].push(taskCount);
        
        emit TaskCreated(taskCount, msg.sender, _title, _reward);
    }
    
    function claimTask(uint256 _taskId) external {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist");
        
        Task storage task = tasks[_taskId];
        
        require(task.status == TaskStatus.OPEN, "Task is not open");
        require(msg.sender != task.creator, "Creator cannot claim own task");
        
        task.assignee = msg.sender;
        task.status = TaskStatus.CLAIMED;
        
        assigneeTasks[msg.sender].push(_taskId);
        
        emit TaskClaimed(_taskId, msg.sender);
    }
    
    function completeTask(uint256 _taskId) external {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist");
        
        Task storage task = tasks[_taskId];
        
        require(msg.sender == task.creator, "Only creator can mark task as completed");
        require(task.status == TaskStatus.CLAIMED, "Task is not claimed");
        require(task.assignee != address(0), "No assignee for this task");
        
        task.status = TaskStatus.COMPLETED;
        task.completedTime = block.timestamp;
        
        (bool success, ) = payable(task.assignee).call{value: task.reward}("");
        require(success, "Reward transfer failed");
        
        emit TaskCompleted(_taskId, task.assignee, task.reward);
    }
    
    function cancelTask(uint256 _taskId) external {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist");
        
        Task storage task = tasks[_taskId];
        
        require(msg.sender == task.creator, "Only creator can cancel task");
        require(task.status == TaskStatus.OPEN || task.status == TaskStatus.CLAIMED, "Task cannot be cancelled");
        
        task.status = TaskStatus.CANCELLED;
        
        // Refund reward to creator
        (bool success, ) = payable(task.creator).call{value: task.reward}("");
        require(success, "Refund transfer failed");
        
        emit TaskCancelled(_taskId);
    }
    
    function getTask(uint256 _taskId) external view returns (
        uint256 id,
        string memory title,
        string memory description,
        uint256 reward,
        address creator,
        address assignee,
        TaskStatus status,
        uint256 createdTime,
        uint256 completedTime
    ) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist");
        
        Task memory task = tasks[_taskId];
        
        return (
            task.id,
            task.title,
            task.description,
            task.reward,
            task.creator,
            task.assignee,
            task.status,
            task.createdTime,
            task.completedTime
        );
    }
    
    function getCreatorTasks(address _creator) external view returns (uint256[] memory) {
        return creatorTasks[_creator];
    }
    
    function getAssigneeTasks(address _assignee) external view returns (uint256[] memory) {
        return assigneeTasks[_assignee];
    }
    
    function getOpenTasks() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openCount++;
            }
        }
        
        uint256[] memory openTaskIds = new uint256[](openCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openTaskIds[index] = i;
                index++;
            }
        }
        
        return openTaskIds;
    }
    
    function getMyClaimedTasks() external view returns (uint256[] memory) {
        uint256 claimedCount = 0;
        
        uint256[] memory myTasks = assigneeTasks[msg.sender];
        
        for (uint256 i = 0; i < myTasks.length; i++) {
            if (tasks[myTasks[i]].status == TaskStatus.CLAIMED) {
                claimedCount++;
            }
        }
        
        uint256[] memory claimedTaskIds = new uint256[](claimedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < myTasks.length; i++) {
            if (tasks[myTasks[i]].status == TaskStatus.CLAIMED) {
                claimedTaskIds[index] = myTasks[i];
                index++;
            }
        }
        
        return claimedTaskIds;
    }
    
    function getMyCompletedTasks() external view returns (uint256[] memory) {
        uint256 completedCount = 0;
        
        uint256[] memory myTasks = assigneeTasks[msg.sender];
        
        for (uint256 i = 0; i < myTasks.length; i++) {
            if (tasks[myTasks[i]].status == TaskStatus.COMPLETED) {
                completedCount++;
            }
        }
        
        uint256[] memory completedTaskIds = new uint256[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < myTasks.length; i++) {
            if (tasks[myTasks[i]].status == TaskStatus.COMPLETED) {
                completedTaskIds[index] = myTasks[i];
                index++;
            }
        }
        
        return completedTaskIds;
    }
    
    function getUserEarnings(address _user) external view returns (uint256) {
        uint256 totalEarnings = 0;
        uint256[] memory userTasks = assigneeTasks[_user];
        
        for (uint256 i = 0; i < userTasks.length; i++) {
            if (tasks[userTasks[i]].status == TaskStatus.COMPLETED) {
                totalEarnings += tasks[userTasks[i]].reward;
            }
        }
        
        return totalEarnings;
    }
    
    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit a positive amount");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
