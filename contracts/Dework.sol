// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.20 <0.9.0;

import {EmployerProfile} from "contracts/types/EmployerProfile.sol";
import {CreateJobListingProps} from "contracts/types/EmployerProfile.sol";

contract Dework {
    uint256 public connectFee = 100;

    EmployerProfile[] public employerProfiles;
    mapping(uint256 => address) public employerProfileAddress;

    address public owner;

    // --- CONSTRUCTOR ---
    constructor() payable {
        owner = msg.sender;
    }

    // --- JOB LISTING STORAGE ---
    struct JobListing {
        uint256 id;
        uint256 employerId;
        string title;
        string jobDescription;
        uint256 deadline;
        uint256 fixedPriceInWei;
        address employer;
        bool isActive;
    }

    JobListing[] public jobListings;
    mapping(uint256 => uint256[]) public employerJobListings; // employerId => jobListingIds

    // --- EVENTS ---
    event EmployerProfileRegistered(uint256 empId, address caller);
    event JobListingCreated(
        uint256 indexed jobId,
        uint256 indexed employerId,
        address employer,
        uint256 fixedPriceInWei
    );
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- ERRORS ---
    error Dework_RevertForJobCreationFeeFunc(
        uint256 expectedFee,
        uint256 actualFee
    );
    error Dework__NotEmployer();
    error Dework__EmployerProfileDoesNotExist();
    error Dework__DeadlineMustBeInFuture();
    error Dework__TitleCannotBeEmpty();
    error Dework__TransferFailed();
    error Dework__NoFeesToWithdraw();
    error Dework__NotAuthorized();

    function getUserid() public view returns (uint256) {
        return employerProfiles.length;
    }

    function registerEmployerProfile(string calldata _name) public {
        if (bytes(_name).length == 0) {
            revert Dework__TitleCannotBeEmpty();
        }

        uint256 empId = getUserid();

        employerProfiles.push(
            EmployerProfile({
                id: empId,
                name: _name,
                isHiring: true,
                wallet: msg.sender
            })
        );
        employerProfileAddress[empId] = msg.sender;
        emit EmployerProfileRegistered(empId, msg.sender);
    }

    // --- GETTER FUNCTIONS ---

    /// @notice Fetch a single employer profile by ID/index
    function getEmployerProfile(
        uint256 _id
    ) public view returns (EmployerProfile memory) {
        require(
            _id < employerProfiles.length,
            "Employer profile does not exist"
        );
        return employerProfiles[_id];
    }

    /// @notice Fetch all employer profiles at once
    function getAllEmployerProfiles()
        public
        view
        returns (EmployerProfile[] memory)
    {
        return employerProfiles;
    }

    /// @notice Get total number of job listings
    function getJobListingCount() public view returns (uint256) {
        return jobListings.length;
    }

    /// @notice Fetch a single job listing by ID
    function getJobListing(
        uint256 _id
    ) public view returns (JobListing memory) {
        require(_id < jobListings.length, "Job listing does not exist");
        return jobListings[_id];
    }

    /// @notice Get all job listing IDs for a specific employer
    function getEmployerJobListings(
        uint256 _employerId
    ) public view returns (uint256[] memory) {
        return employerJobListings[_employerId];
    }

    // --- JOB LISTING FUNCTIONS ---

    /// @notice Create a new job listing. Must send exactly fixedPriceInWei in ETH.
    /// @param employerId The ID of the employer profile (must be owned by caller)
    /// @param joblistingInput Struct containing job details
    function createJobListing(
        uint256 employerId,
        CreateJobListingProps calldata joblistingInput
    ) external payable {
        // --- VALIDATION: Employer profile exists ---
        if (employerId >= employerProfiles.length) {
            revert Dework__EmployerProfileDoesNotExist();
        }

        // --- ACCESS CONTROL: Only the profile owner can create listings ---
        if (employerProfileAddress[employerId] != msg.sender) {
            revert Dework__NotEmployer();
        }

        // --- VALIDATION: Title not empty ---
        if (bytes(joblistingInput.title).length == 0) {
            revert Dework__TitleCannotBeEmpty();
        }

        // --- VALIDATION: Deadline must be in the future ---
        if (
            joblistingInput.deadline != 0 &&
            joblistingInput.deadline <= block.timestamp
        ) {
            revert Dework__DeadlineMustBeInFuture();
        }

        // --- FEE CHECK: msg.value must exactly match fixedPriceInWei ---
        uint256 fixedPriceForJobEntry = joblistingInput.fixedPriceInWei;
        if (msg.value != fixedPriceForJobEntry) {
            revert Dework_RevertForJobCreationFeeFunc(
                fixedPriceForJobEntry,
                msg.value
            );
        }

        // --- STORE THE JOB LISTING ---
        uint256 jobId = jobListings.length;
        jobListings.push(
            JobListing({
                id: jobId,
                employerId: employerId,
                title: joblistingInput.title,
                jobDescription: joblistingInput.jobDescription,
                deadline: joblistingInput.deadline,
                fixedPriceInWei: fixedPriceForJobEntry,
                employer: msg.sender,
                isActive: true
            })
        );
        employerJobListings[employerId].push(jobId);

        emit JobListingCreated(
            jobId,
            employerId,
            msg.sender,
            fixedPriceForJobEntry
        );
    }

    // --- FEE MANAGEMENT ---

    /// @notice Withdraw collected fees (only the deployer/owner)
    function withdrawFees(address payable _to) external {
        if (msg.sender != owner) {
            revert Dework__NotAuthorized();
        }
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert Dework__NoFeesToWithdraw();
        }
        (bool success, ) = _to.call{value: balance}("");
        if (!success) {
            revert Dework__TransferFailed();
        }
        emit FeesWithdrawn(_to, balance);
    }
}
