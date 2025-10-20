// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventAttendance {
    address public owner;
    string public eventName;
    mapping(address => uint256) public checkInTimes;
    address[] public attendees;

    event CheckedIn(address indexed attendee, uint256 timestamp);

    constructor(string memory _eventName) {
        owner = msg.sender;
        eventName = _eventName;
    }

    function checkIn() public {
        require(checkInTimes[msg.sender] == 0, "You have already checked in.");
        
        checkInTimes[msg.sender] = block.timestamp;
        attendees.push(msg.sender);

        emit CheckedIn(msg.sender, block.timestamp);
    }

    function hasCheckedIn(address _attendee) public view returns (bool) {
        return checkInTimes[_attendee] > 0;
    }

    function getCheckInTime(address _attendee) public view returns (uint256) {
        return checkInTimes[_attendee];
    }

    function getAttendeeCount() public view returns (uint256) {
        return attendees.length;
    }

    function getAttendees() public view returns (address[] memory) {
        return attendees;
    }
}
