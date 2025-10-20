// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint256 id;
        string title;
        string description;
        address employer;
        bool isOpen;
    }

    struct Application {
        address worker;
        uint256 jobId;
    }

    Job[] public jobs;
    Application[] public applications;
    uint256 public jobCounter;

    event JobPosted(uint256 indexed id, string title, address indexed employer);
    event JobApplied(uint256 indexed jobId, address indexed worker);
    event JobClosed(uint256 indexed id);

    function postJob(string memory _title, string memory _description) public {
        jobCounter++;
        jobs.push(Job(jobCounter, _title, _description, msg.sender, true));
        emit JobPosted(jobCounter, _title, msg.sender);
    }

    function applyForJob(uint256 _jobId) public {
        require(_jobId > 0 && _jobId <= jobCounter, "Job does not exist.");
        Job storage job = jobs[_jobId - 1]; // Adjust for 0-based index
        require(job.isOpen, "This job is closed.");
        require(msg.sender != job.employer, "Employer cannot apply for their own job.");

        applications.push(Application(msg.sender, _jobId));
        emit JobApplied(_jobId, msg.sender);
    }

    function closeJob(uint256 _jobId) public {
        require(_jobId > 0 && _jobId <= jobCounter, "Job does not exist.");
        Job storage job = jobs[_jobId - 1]; // Adjust for 0-based index
        require(msg.sender == job.employer, "Only the employer can close the job.");
        require(job.isOpen, "Job is already closed.");

        job.isOpen = false;
        emit JobClosed(_jobId);
    }

    function getJob(uint256 _jobId) public view returns (uint256, string memory, string memory, address, bool) {
        require(_jobId > 0 && _jobId <= jobCounter, "Job does not exist.");
        Job storage job = jobs[_jobId - 1]; // Adjust for 0-based index
        return (job.id, job.title, job.description, job.employer, job.isOpen);
    }
    
    function getJobCount() public view returns (uint256) {
        return jobs.length;
    }

    function getApplicationCount() public view returns (uint256) {
        return applications.length;
    }
}
