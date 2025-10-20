// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attendance {
    string public eventName;
    mapping(address => bool) public checkedIn;
    address[] public attendees;

    event CheckedIn(address indexed user);

    constructor(string memory _eventName) {
        eventName = _eventName;
    }

    function checkIn() external {
        require(!checkedIn[msg.sender], "Already checked in");
        checkedIn[msg.sender] = true;
        attendees.push(msg.sender);
        emit CheckedIn(msg.sender);
    }

    function getAttendees() external view returns (address[] memory) {
        return attendees;
    }
}
