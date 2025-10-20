// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint256 id;
        address employer;
        string description;
        address[] applicants;
        bool open;
    }

    uint256 public nextJobId;
    mapping(uint256 => Job) public jobs;

    event JobPosted(uint256 indexed id, address indexed employer, string description);
    event Applied(uint256 indexed jobId, address indexed applicant);
    event JobClosed(uint256 indexed jobId);

    function postJob(string calldata description) external {
        require(bytes(description).length > 0, "Description required");
        jobs[nextJobId].id = nextJobId;
        jobs[nextJobId].employer = msg.sender;
        jobs[nextJobId].description = description;
        jobs[nextJobId].open = true;
        emit JobPosted(nextJobId, msg.sender, description);
        nextJobId++;
    }

    function applyForJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(job.open, "Job closed");
        for (uint i = 0; i < job.applicants.length; i++) {
            require(job.applicants[i] != msg.sender, "Already applied");
        }
        job.applicants.push(msg.sender);
        emit Applied(jobId, msg.sender);
    }

    function closeJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.employer, "Not employer");
        require(job.open, "Already closed");
        job.open = false;
        emit JobClosed(jobId);
    }

    function getApplicants(uint256 jobId) external view returns (address[] memory) {
        return jobs[jobId].applicants;
    }
}
