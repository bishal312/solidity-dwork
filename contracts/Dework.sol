// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.34;

import {EmployerProfile} from "contracts/types/EmployerProfile.sol";

contract Dework {
    uint256 public connectFee = 100;

    EmployerProfile[] public employerProfiles;

    function getUserid() public view returns (uint256) {
        return employerProfiles.length;
    }

    function registerEmployerProfile(string calldata _name) public {
        uint256 empId = getUserid();

        employerProfiles.push(
            EmployerProfile({
                id: empId,
                name: _name,
                isHiring: true,
                wallet: msg.sender
            })
        );
    }

    // --- GETTER FUNCTIONS ---

    /// @notice Fetch a single employer profile by ID/index
    function getEmployerProfile(uint256 _id) public view returns (EmployerProfile memory) {
        require(_id < employerProfiles.length, "Employer profile does not exist");
        return employerProfiles[_id];
    }

    /// @notice Fetch all employer profiles at once
    function getAllEmployerProfiles() public view returns (EmployerProfile[] memory) {
        return employerProfiles;
    }
}
