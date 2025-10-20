// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventAttendance
 * @dev A contract to log attendance for an event. Users can check in with their wallet address.
 */
contract EventAttendance {
    // The address of the event organizer who can manage the event.
    address public owner;

    // The name of the event.
    string public eventName;

    // Flag to control if check-ins are currently allowed.
    bool public isCheckInOpen;

    // Mapping to track which addresses have checked in.
    mapping(address => bool) private hasCheckedIn;

    // An array to store the addresses of all attendees.
    address[] public attendees;

    /**
     * @dev Emitted when the check-in for the event is opened.
     * @param eventName The name of the event.
     */
    event CheckInOpened(string eventName);

    /**
     * @dev Emitted when the check-in for the event is closed.
     */
    event CheckInClosed();

    /**
     * @dev Emitted when a user checks in to the event.
     * @param attendee The address of the user who checked in.
     */
    event UserCheckedIn(address indexed attendee);

    modifier onlyOwner() {
        require(msg.sender == owner, "EventAttendance: Caller is not the owner.");
        _;
    }

    /**
     * @dev Sets the event name and the owner of the contract.
     * @param _eventName The name of the event.
     */
    constructor(string memory _eventName) {
        owner = msg.sender;
        eventName = _eventName;
        isCheckInOpen = false; // Check-in is closed by default.
    }

    /**
     * @dev Opens the check-in for the event. Can only be called by the owner.
     */
    function openCheckIn() public onlyOwner {
        require(!isCheckInOpen, "EventAttendance: Check-in is already open.");
        isCheckInOpen = true;
        emit CheckInOpened(eventName);
    }

    /**
     * @dev Closes the check-in for the event. Can only be called by the owner.
     */
    function closeCheckIn() public onlyOwner {
        require(isCheckInOpen, "EventAttendance: Check-in is not open.");
        isCheckInOpen = false;
        emit CheckInClosed();
    }

    /**
     * @dev Allows a user to check in to the event.
     */
    function checkIn() public {
        require(isCheckInOpen, "EventAttendance: Check-in is not currently open.");
        require(!hasCheckedIn[msg.sender], "EventAttendance: You have already checked in.");

        hasCheckedIn[msg.sender] = true;
        attendees.push(msg.sender);

        emit UserCheckedIn(msg.sender);
    }

    /**
     * @dev Verifies if a specific user has checked in.
     * @param _user The address of the user to verify.
     * @return True if the user has checked in, false otherwise.
     */
    function verifyAttendance(address _user) public view returns (bool) {
        return hasCheckedIn[_user];
    }

    /**
     * @dev Returns the list of all attendees who have checked in.
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
