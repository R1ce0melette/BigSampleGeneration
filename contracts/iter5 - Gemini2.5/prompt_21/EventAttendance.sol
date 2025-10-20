// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventAttendance
 * @dev A contract to log attendance for an event using wallet addresses.
 */
contract EventAttendance {

    address public owner;
    string public eventName;
    mapping(address => bool) public hasCheckedIn;
    address[] public attendees;

    event CheckedIn(address indexed attendee, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    /**
     * @dev Sets the event name and owner upon deployment.
     * @param _eventName The name of the event.
     */
    constructor(string memory _eventName) {
        owner = msg.sender;
        eventName = _eventName;
    }

    /**
     * @dev Allows a user to check in to the event.
     */
    function checkIn() public {
        require(!hasCheckedIn[msg.sender], "You have already checked in.");
        
        hasCheckedIn[msg.sender] = true;
        attendees.push(msg.sender);
        
        emit CheckedIn(msg.sender, block.timestamp);
    }

    /**
     * @dev Verifies if a user has checked in.
     * @param _user The address to check.
     * @return A boolean indicating if the user has checked in.
     */
    function verifyAttendance(address _user) public view returns (bool) {
        return hasCheckedIn[_user];
    }

    /**
     * @dev Returns the list of all attendees.
     * @return An array of attendee addresses.
     */
    function getAttendees() public view returns (address[] memory) {
        return attendees;
    }

    /**
     * @dev Returns the total number of attendees.
     * @return The count of attendees.
     */
    function getAttendeeCount() public view returns (uint256) {
        return attendees.length;
    }
}
