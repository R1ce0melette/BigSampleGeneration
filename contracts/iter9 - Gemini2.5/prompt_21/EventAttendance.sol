// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventAttendance {
    address public owner;
    string public eventName;
    mapping(address => bool) public hasCheckedIn;
    address[] public attendees;

    event CheckedIn(address indexed attendee, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(string memory _eventName) {
        owner = msg.sender;
        eventName = _eventName;
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

    function hasUserCheckedIn(address _user) public view returns (bool) {
        return hasCheckedIn[_user];
    }

    function setEventName(string memory _newEventName) public onlyOwner {
        eventName = _newEventName;
    }
}
