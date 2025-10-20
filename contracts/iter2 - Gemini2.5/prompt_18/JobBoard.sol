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
        address applicant;
        uint256 jobId;
    }

    Job[] public jobs;
    Application[] public applications;
    mapping(uint256 => address[]) public applicantsPerJob;
    mapping(address => uint[]) public jobsAppliedBy;

    uint256 public jobCount;

    event JobPosted(uint256 id, string title, address indexed employer);
    event JobClosed(uint256 id, address indexed employer);
    event Applied(uint256 jobId, address indexed applicant);

    function postJob(string memory _title, string memory _description) public {
        require(bytes(_title).length > 0, "Job title cannot be empty.");
        jobCount++;
        jobs.push(Job(jobCount, _title, _description, msg.sender, true));
        emit JobPosted(jobCount, _title, msg.sender);
    }

    function applyForJob(uint256 _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        Job storage job = jobs[_jobId - 1];
        require(job.isOpen, "This job is closed.");
        
        // Check if already applied
        for(uint i = 0; i < applicantsPerJob[_jobId].length; i++) {
            require(applicantsPerJob[_jobId][i] != msg.sender, "You have already applied for this job.");
        }

        applications.push(Application(msg.sender, _jobId));
        applicantsPerJob[_jobId].push(msg.sender);
        jobsAppliedBy[msg.sender].push(_jobId);
        emit Applied(_jobId, msg.sender);
    }

    function closeJob(uint256 _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        Job storage job = jobs[_jobId - 1];
        require(job.employer == msg.sender, "Only the employer can close the job.");
        require(job.isOpen, "Job is already closed.");

        job.isOpen = false;
        emit JobClosed(_jobId, msg.sender);
    }

    function getJob(uint256 _jobId) public view returns (uint256, string memory, string memory, address, bool) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        Job storage job = jobs[_jobId - 1];
        return (job.id, job.title, job.description, job.employer, job.isOpen);
    }

    function getApplicantsForJob(uint256 _jobId) public view returns (address[] memory) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        return applicantsPerJob[_jobId];
    }
}
