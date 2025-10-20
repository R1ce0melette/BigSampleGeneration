// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttendanceLogger {
    address public owner;
    mapping(address => bool) public hasCheckedIn;
    address[] public attendees;

    event CheckedIn(address indexed attendee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function checkIn() public {
        require(!hasCheckedIn[msg.sender], "You have already checked in.");
        hasCheckedIn[msg.sender] = true;
        attendees.push(msg.sender);
        emit CheckedIn(msg.sender);
    }

    function getAttendees() public view returns (address[] memory) {
        return attendees;
    }

    function getAttendeeCount() public view returns (uint256) {
        return attendees.length;
    }

    function resetAttendance() public onlyOwner {
        for (uint i = 0; i < attendees.length; i++) {
            hasCheckedIn[attendees[i]] = false;
        }
        delete attendees;
    }
}
