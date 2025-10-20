// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint id;
        string title;
        string description;
        address employer;
        bool isOpen;
    }

    struct Application {
        address worker;
        uint jobId;
    }

    Job[] public jobs;
    Application[] public applications;
    uint public jobCount;

    mapping(uint => address[]) public jobApplicants;

    event JobPosted(uint id, string title, address indexed employer);
    event Applied(uint jobId, address indexed worker);

    function postJob(string memory _title, string memory _description) public {
        jobCount++;
        jobs.push(Job(jobCount, _title, _description, msg.sender, true));
        emit JobPosted(jobCount, _title, msg.sender);
    }

    function apply(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        require(jobs[_jobId - 1].isOpen, "This job is no longer open.");

        // Check if the worker has already applied for this job
        for (uint i = 0; i < jobApplicants[_jobId].length; i++) {
            require(jobApplicants[_jobId][i] != msg.sender, "You have already applied for this job.");
        }

        applications.push(Application(msg.sender, _jobId));
        jobApplicants[_jobId].push(msg.sender);
        emit Applied(_jobId, msg.sender);
    }

    function closeJob(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        Job storage job = jobs[_jobId - 1];
        require(job.employer == msg.sender, "Only the employer can close the job.");
        job.isOpen = false;
    }

    function getJob(uint _jobId) public view returns (uint, string memory, string memory, address, bool) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        Job storage job = jobs[_jobId - 1];
        return (job.id, job.title, job.description, job.employer, job.isOpen);
    }

    function getApplicants(uint _jobId) public view returns (address[] memory) {
        require(_jobId > 0 && _jobId <= jobCount, "Job does not exist.");
        return jobApplicants[_jobId];
    }
}
