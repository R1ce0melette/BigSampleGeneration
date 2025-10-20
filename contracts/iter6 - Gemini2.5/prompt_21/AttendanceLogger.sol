// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttendanceLogger {
    address public eventOrganizer;
    mapping(address => bool) public hasCheckedIn;
    address[] public attendees;

    event CheckedIn(address indexed attendee, uint256 timestamp);

    constructor() {
        eventOrganizer = msg.sender;
    }

    function checkIn() public {
        require(!hasCheckedIn[msg.sender], "You have already checked in.");
        
        hasCheckedIn[msg.sender] = true;
        attendees.push(msg.sender);

        emit CheckedIn(msg.sender, block.timestamp);
    }

    function getAttendees() public view returns (address[] memory) {
        return attendees;
    }

    function getAttendeeCount() public view returns (uint256) {
        return attendees.length;
    }
}
