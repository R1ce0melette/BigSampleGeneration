// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    struct Job {
        uint256 id;
        address employer;
        string description;
        address[] applicants;
    }

    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => mapping(address => bool)) public hasApplied;

    event JobPosted(uint256 indexed id, address indexed employer, string description);
    event Applied(uint256 indexed jobId, address indexed worker);

    function postJob(string calldata description) external {
        require(bytes(description).length > 0, "Description required");
        jobCount++;
        jobs[jobCount].id = jobCount;
        jobs[jobCount].employer = msg.sender;
        jobs[jobCount].description = description;
        emit JobPosted(jobCount, msg.sender, description);
    }

    function applyForJob(uint256 jobId) external {
        require(jobId > 0 && jobId <= jobCount, "Invalid job");
    require(!hasApplied[jobId][msg.sender], "Already applied");
    jobs[jobId].applicants.push(msg.sender);
    hasApplied[jobId][msg.sender] = true;
    emit Applied(jobId, msg.sender);
    }

    function getApplicants(uint256 jobId) external view returns (address[] memory) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job");
        return jobs[jobId].applicants;
    }
}
