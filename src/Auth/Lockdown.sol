// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

// Lockdown duration is hard coded to 14 days.
uint64 constant lockdownDuration = 14 days;

/// @title Lockdown Contract
/// @author jtriley2p
/// @notice Minimal contract capable of issuing temporary lockdowns on admin functions. The lockdown
///         authorities MUST be independent of the administrator as a backstop against malicious
///         actions by the administrator, particularly when admin functions are timelocked.
/// @notice There is also a cooldown equal to the lockdown duration such that the lockdown authority
///         cannot halt administrator behavior indefinitely.
abstract contract Lockdown {
    /// @notice Logged when lockdown authority transfer is initiated.
    /// @param newAuthority Next lockdown authority.
    event SendLockdownAuthority(address indexed newAuthority);

    /// @notice Logged when lockdown authority transfer is finalized.
    event ReceiveLockdownAuthority();

    /// @notice Logged when lockdown is initiated.
    event InitiateLockdown();

    /// @notice Lockdown authority address (ideally a council-controlled contract).
    address public lockdownAuthority;

    /// @notice Pending lockdown authority recipient, if any.
    /// @dev Null if no transfer is active.
    address public pendingLockdownAuthority;

    /// @notice Last lockdown timestamp.
    uint64 public lastLockdown;

    /// @notice Queries if contract is in lockdown.
    /// @return Returns true if contract is in lockdown.
    function inLockdown() public view returns (bool) {
        return lastLockdown + lockdownDuration >= block.timestamp;
    }

    /// @notice Initiates lockdown.
    /// @dev Throws if there was a lockdown in the last 28 days.
    function initiateLockdown() public {
        require(msg.sender == pendingLockdownAuthority);
        require(block.timestamp >= lastLockdown + 2 * lockdownDuration);

        lastLockdown = uint64(block.timestamp);

        emit InitiateLockdown();
    }

    /// @notice Sends lockdown authority permission.
    /// @param newAuthority Next authority.
    /// @dev MUST be received by the next lockdown authority to be valid.
    function sendLockdownAuthority(address newAuthority) public {
        require(msg.sender == lockdownAuthority);

        pendingLockdownAuthority = newAuthority;

        emit SendLockdownAuthority(newAuthority);
    }

    /// @notice Receives lockdown authority permission.
    function receiveLockdownAuthority() public {
        require(msg.sender == pendingLockdownAuthority);

        lockdownAuthority = msg.sender;

        delete pendingLockdownAuthority;

        emit ReceiveLockdownAuthority();
    }
}
