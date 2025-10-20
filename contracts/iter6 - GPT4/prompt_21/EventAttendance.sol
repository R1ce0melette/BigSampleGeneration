// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventAttendance {
    mapping(address => bool) public checkedIn;
    address[] public attendees;

    event CheckedIn(address indexed user);

    function checkIn() external {
        require(!checkedIn[msg.sender], "Already checked in");
        checkedIn[msg.sender] = true;
        attendees.push(msg.sender);
        emit CheckedIn(msg.sender);
    }

    function isCheckedIn(address user) external view returns (bool) {
        return checkedIn[user];
    }

    function getAttendees() external view returns (address[] memory) {
        return attendees;
    }
}
