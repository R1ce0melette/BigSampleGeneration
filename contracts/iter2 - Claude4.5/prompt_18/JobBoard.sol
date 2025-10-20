// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobBoard {
    enum JobStatus { OPEN, CLOSED, FILLED }
    
    struct Job {
        uint256 jobId;
        address employer;
        string title;
        string description;
        uint256 payment;
        JobStatus status;
        uint256 createdAt;
        address[] applicants;
        address selectedWorker;
    }
    
    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(uint256 => mapping(address => bool)) public hasApplied;
    mapping(address => uint256[]) public employerJobs;
    mapping(address => uint256[]) public workerApplications;
    
    event JobPosted(uint256 indexed jobId, address indexed employer, string title, uint256 payment);
    event ApplicationSubmitted(uint256 indexed jobId, address indexed worker);
    event WorkerSelected(uint256 indexed jobId, address indexed worker);
    event JobClosed(uint256 indexed jobId);
    event PaymentReleased(uint256 indexed jobId, address indexed worker, uint256 amount);
    
    modifier onlyEmployer(uint256 _jobId) {
        require(msg.sender == jobs[_jobId].employer, "Only employer can call this");
        _;
    }
    
    modifier jobExists(uint256 _jobId) {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        _;
    }
    
    function postJob(string memory _title, string memory _description) external payable {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(msg.value > 0, "Payment must be greater than 0");
        
        jobCount++;
        
        Job storage newJob = jobs[jobCount];
        newJob.jobId = jobCount;
        newJob.employer = msg.sender;
        newJob.title = _title;
        newJob.description = _description;
        newJob.payment = msg.value;
        newJob.status = JobStatus.OPEN;
        newJob.createdAt = block.timestamp;
        
        employerJobs[msg.sender].push(jobCount);
        
        emit JobPosted(jobCount, msg.sender, _title, msg.value);
    }
    
    function applyForJob(uint256 _jobId) external jobExists(_jobId) {
        Job storage job = jobs[_jobId];
        
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(msg.sender != job.employer, "Employer cannot apply to their own job");
        require(!hasApplied[_jobId][msg.sender], "Already applied to this job");
        
        job.applicants.push(msg.sender);
        hasApplied[_jobId][msg.sender] = true;
        workerApplications[msg.sender].push(_jobId);
        
        emit ApplicationSubmitted(_jobId, msg.sender);
    }
    
    function selectWorker(uint256 _jobId, address _worker) external 
        jobExists(_jobId) 
        onlyEmployer(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        require(job.status == JobStatus.OPEN, "Job is not open");
        require(hasApplied[_jobId][_worker], "Worker has not applied");
        
        job.selectedWorker = _worker;
        job.status = JobStatus.FILLED;
        
        emit WorkerSelected(_jobId, _worker);
    }
    
    function releasePayment(uint256 _jobId) external 
        jobExists(_jobId) 
        onlyEmployer(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        require(job.status == JobStatus.FILLED, "Job is not filled");
        require(job.selectedWorker != address(0), "No worker selected");
        
        uint256 payment = job.payment;
        job.payment = 0;
        
        (bool success, ) = payable(job.selectedWorker).call{value: payment}("");
        require(success, "Payment transfer failed");
        
        emit PaymentReleased(_jobId, job.selectedWorker, payment);
    }
    
    function closeJob(uint256 _jobId) external 
        jobExists(_jobId) 
        onlyEmployer(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        require(job.status == JobStatus.OPEN, "Job is not open");
        
        job.status = JobStatus.CLOSED;
        
        // Refund payment to employer
        if (job.payment > 0) {
            uint256 refund = job.payment;
            job.payment = 0;
            
            (bool success, ) = payable(job.employer).call{value: refund}("");
            require(success, "Refund transfer failed");
        }
        
        emit JobClosed(_jobId);
    }
    
    function getJob(uint256 _jobId) external view jobExists(_jobId) returns (
        address employer,
        string memory title,
        string memory description,
        uint256 payment,
        JobStatus status,
        uint256 createdAt,
        uint256 applicantCount,
        address selectedWorker
    ) {
        Job storage job = jobs[_jobId];
        
        return (
            job.employer,
            job.title,
            job.description,
            job.payment,
            job.status,
            job.createdAt,
            job.applicants.length,
            job.selectedWorker
        );
    }
    
    function getApplicants(uint256 _jobId) external view jobExists(_jobId) returns (address[] memory) {
        return jobs[_jobId].applicants;
    }
    
    function getEmployerJobs(address _employer) external view returns (uint256[] memory) {
        return employerJobs[_employer];
    }
    
    function getWorkerApplications(address _worker) external view returns (uint256[] memory) {
        return workerApplications[_worker];
    }
    
    function getOpenJobs() external view returns (uint256[] memory) {
        uint256 openCount = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                openCount++;
            }
        }
        
        uint256[] memory openJobs = new uint256[](openCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= jobCount; i++) {
            if (jobs[i].status == JobStatus.OPEN) {
                openJobs[index] = i;
                index++;
            }
        }
        
        return openJobs;
    }
    
    function hasWorkerApplied(uint256 _jobId, address _worker) external view returns (bool) {
        return hasApplied[_jobId][_worker];
    }
}
