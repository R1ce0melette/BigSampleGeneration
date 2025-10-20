// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AttendanceLogger is Ownable {
    // Mapping from an event ID to a nested mapping of attendees to their check-in status
    mapping(uint256 => mapping(address => bool)) public eventAttendance;
    // Mapping from an event ID to an array of all attendees for that event
    mapping(uint256 => address[]) public attendeesPerEvent;

    uint256 public eventCount;

    event EventCreated(uint256 indexed eventId, string description);
    event CheckedIn(uint256 indexed eventId, address indexed attendee);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Creates a new event for which attendance can be logged.
     * @param _description A short description of the event.
     */
    function createEvent(string memory _description) public onlyOwner {
        eventCount++;
        emit EventCreated(eventCount, _description);
    }

    /**
     * @dev Allows a user to check in to a specific event.
     * @param _eventId The ID of the event to check in to.
     */
    function checkIn(uint256 _eventId) public {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist.");
        require(!eventAttendance[_eventId][msg.sender], "You have already checked in to this event.");

        eventAttendance[_eventId][msg.sender] = true;
        attendeesPerEvent[_eventId].push(msg.sender);

        emit CheckedIn(_eventId, msg.sender);
    }

    /**
     * @dev Checks if a specific user has checked in to an event.
     * @param _eventId The ID of the event.
     * @param _user The address of the user.
     * @return True if the user has checked in, false otherwise.
     */
    function hasCheckedIn(uint256 _eventId, address _user) public view returns (bool) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist.");
        return eventAttendance[_eventId][_user];
    }

    /**
     * @dev Retrieves the list of all attendees for a specific event.
     * @param _eventId The ID of the event.
     * @return An array of addresses of all attendees.
     */
    function getAttendees(uint256 _eventId) public view returns (address[] memory) {
        require(_eventId > 0 && _eventId <= eventCount, "Event does not exist.");
        return attendeesPerEvent[_eventId];
    }
}
