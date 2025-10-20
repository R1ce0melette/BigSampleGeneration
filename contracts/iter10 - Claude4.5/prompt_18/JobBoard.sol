// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint256 id;
        address employer;
        string title;
        string description;
        uint256 payment;
        bool active;
        bool completed;
        address selectedWorker;
        uint256 applicantCount;
    }

    struct Application {
        address worker;
        uint256 timestamp;
    }

    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => Application[]) public jobApplications;
    mapping(uint256 => mapping(address => bool)) public hasApplied;

    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment);
    event ApplicationSubmitted(uint256 indexed jobId, address indexed worker, uint256 timestamp);
    event WorkerSelected(uint256 indexed jobId, address indexed worker);
    event JobCompleted(uint256 indexed jobId, address indexed worker, uint256 payment);
    event JobCancelled(uint256 indexed jobId);

    function postJob(string memory title, string memory description) external payable {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(msg.value > 0, "Must provide payment for the job");

        jobCount++;

        jobs[jobCount] = Job({
            id: jobCount,
            employer: msg.sender,
            title: title,
            description: description,
            payment: msg.value,
            active: true,
            completed: false,
            selectedWorker: address(0),
            applicantCount: 0
        });

        emit JobPosted(jobCount, msg.sender, title, msg.value);
    }

    function applyForJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        Job storage job = jobs[jobId];
        require(job.active, "Job is not active");
        require(!job.completed, "Job is already completed");
        require(msg.sender != job.employer, "Employer cannot apply for their own job");
        require(!hasApplied[jobId][msg.sender], "Already applied for this job");

        jobApplications[jobId].push(Application({
            worker: msg.sender,
            timestamp: block.timestamp
        }));

        hasApplied[jobId][msg.sender] = true;
        job.applicantCount++;

        emit ApplicationSubmitted(jobId, msg.sender, block.timestamp);
    }

    function selectWorker(uint256 jobId, address worker) external {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        Job storage job = jobs[jobId];
        require(msg.sender == job.employer, "Only employer can select worker");
        require(job.active, "Job is not active");
        require(!job.completed, "Job is already completed");
        require(job.selectedWorker == address(0), "Worker already selected");
        require(hasApplied[jobId][worker], "Worker has not applied for this job");

        job.selectedWorker = worker;
        job.active = false;

        emit WorkerSelected(jobId, worker);
    }

    function completeJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        Job storage job = jobs[jobId];
        require(msg.sender == job.employer, "Only employer can complete job");
        require(job.selectedWorker != address(0), "No worker selected");
        require(!job.completed, "Job is already completed");

        job.completed = true;
        uint256 payment = job.payment;

        (bool success, ) = payable(job.selectedWorker).call{value: payment}("");
        require(success, "Payment transfer failed");

        emit JobCompleted(jobId, job.selectedWorker, payment);
    }

    function cancelJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        Job storage job = jobs[jobId];
        require(msg.sender == job.employer, "Only employer can cancel job");
        require(job.active, "Job is not active");
        require(!job.completed, "Job is already completed");
        require(job.selectedWorker == address(0), "Cannot cancel after selecting worker");

        job.active = false;
        uint256 refundAmount = job.payment;

        (bool success, ) = payable(job.employer).call{value: refundAmount}("");
        require(success, "Refund transfer failed");

        emit JobCancelled(jobId);
    }

    function getJob(uint256 jobId) external view returns (
        uint256 id,
        address employer,
        string memory title,
        string memory description,
        uint256 payment,
        bool active,
        bool completed,
        address selectedWorker,
        uint256 applicantCount
    ) {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        Job memory job = jobs[jobId];
        return (
            job.id,
            job.employer,
            job.title,
            job.description,
            job.payment,
            job.active,
            job.completed,
            job.selectedWorker,
            job.applicantCount
        );
    }

    function getJobApplications(uint256 jobId) external view returns (Application[] memory) {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        return jobApplications[jobId];
    }

    function getActiveJobs() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].active) {
                activeCount++;
            }
        }

        uint256[] memory activeJobIds = new uint256[](activeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].active) {
                activeJobIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return activeJobIds;
    }
}
