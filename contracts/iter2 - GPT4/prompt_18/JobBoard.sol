// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint256 id;
        address employer;
        string description;
        address[] applicants;
    }

    uint256 public nextJobId;
    mapping(uint256 => Job) public jobs;

    event JobPosted(uint256 id, address employer, string description);
    event Applied(uint256 jobId, address worker);

    function postJob(string calldata description) external {
        jobs[nextJobId].id = nextJobId;
        jobs[nextJobId].employer = msg.sender;
        jobs[nextJobId].description = description;
        emit JobPosted(nextJobId, msg.sender, description);
        nextJobId++;
    }

    function applyForJob(uint256 jobId) external {
        require(jobId < nextJobId, "Job does not exist");
        jobs[jobId].applicants.push(msg.sender);
        emit Applied(jobId, msg.sender);
    }

    function getApplicants(uint256 jobId) external view returns (address[] memory) {
        return jobs[jobId].applicants;
    }
}
