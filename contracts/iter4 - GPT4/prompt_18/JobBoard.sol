// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        address employer;
        string description;
        address[] applicants;
    }

    Job[] public jobs;

    event JobPosted(uint256 indexed jobId, address indexed employer, string description);
    event Applied(uint256 indexed jobId, address indexed applicant);

    function postJob(string calldata description) external {
        jobs.push(Job(msg.sender, description, new address[](0)));
        emit JobPosted(jobs.length - 1, msg.sender, description);
    }

    function applyForJob(uint256 jobId) external {
        require(jobId < jobs.length, "Invalid jobId");
        Job storage job = jobs[jobId];
        for (uint256 i = 0; i < job.applicants.length; i++) {
            require(job.applicants[i] != msg.sender, "Already applied");
        }
        job.applicants.push(msg.sender);
        emit Applied(jobId, msg.sender);
    }

    function getJob(uint256 jobId) external view returns (address, string memory, address[] memory) {
        require(jobId < jobs.length, "Invalid jobId");
        Job storage job = jobs[jobId];
        return (job.employer, job.description, job.applicants);
    }

    function getJobCount() external view returns (uint256) {
        return jobs.length;
    }
}
