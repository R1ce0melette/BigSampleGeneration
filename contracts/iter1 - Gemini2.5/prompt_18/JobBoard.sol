// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    address public owner;

    struct Job {
        address employer;
        string description;
        uint256 reward;
        bool isOpen;
        address[] applicants;
    }

    Job[] public jobs;
    mapping(uint256 => mapping(address => bool)) public hasApplied;

    event JobPosted(uint256 indexed jobId, address indexed employer, string description, uint256 reward);
    event JobApplied(uint256 indexed jobId, address indexed applicant);
    event JobClosed(uint256 indexed jobId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function postJob(string calldata _description, uint256 _reward) public {
        uint256 jobId = jobs.length;
        jobs.push(Job({
            employer: msg.sender,
            description: _description,
            reward: _reward,
            isOpen: true,
            applicants: new address[](0)
        }));
        emit JobPosted(jobId, msg.sender, _description, _reward);
    }

    function applyForJob(uint256 _jobId) public {
        require(_jobId < jobs.length, "Job does not exist.");
        Job storage job = jobs[_jobId];
        require(job.isOpen, "Job is not open for applications.");
        require(!hasApplied[_jobId][msg.sender], "You have already applied for this job.");

        job.applicants.push(msg.sender);
        hasApplied[_jobId][msg.sender] = true;
        emit JobApplied(_jobId, msg.sender);
    }

    function closeJob(uint256 _jobId) public {
        require(_jobId < jobs.length, "Job does not exist.");
        Job storage job = jobs[_jobId];
        require(job.employer == msg.sender, "Only the employer can close the job.");
        require(job.isOpen, "Job is already closed.");

        job.isOpen = false;
        emit JobClosed(_jobId);
    }

    function getJob(uint256 _jobId) public view returns (address, string memory, uint256, bool, address[] memory) {
        require(_jobId < jobs.length, "Job does not exist.");
        Job storage job = jobs[_jobId];
        return (job.employer, job.description, job.reward, job.isOpen, job.applicants);
    }

    function getJobCount() public view returns (uint256) {
        return jobs.length;
    }
}
