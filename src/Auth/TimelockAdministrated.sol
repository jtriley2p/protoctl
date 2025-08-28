// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Administrated } from "src/Auth/Administrated.sol";

/// @title Administrated Timelock
/// @author jtriley2p
/// @notice Minimal timelock contract with two-step administrator transfers. Updating timelock
///         requires two steps; admin queues timelock update then admin completes timelock update
///         after the current timelock has passed.
contract TimelockAdministrated is Administrated {
    /// @notice Logged when timelock update is queued.
    /// @param newTimelock New timelock after update.
    event QueueTimelockUpdate(uint64 newTimelock);

    /// @notice Looged when timelock update is finalized.
    event FinalizeTimelockUpdate();

    /// @notice Current timelock.
    uint64 public timelock;

    /// @notice Next timelock to be set. MUST be zero if there is no timelock update queue.
    uint64 public nextTimelock;

    /// @notice Timestamp at which the current queued timelock update, if any, is ready to be
    ///         finalized.
    uint64 public timelockUpdateReadyAt;

    /// @notice Queues a timelock update.
    /// @param newTimelock New timelock after update finalizeds.
    function queueTimelockUpdate(uint64 newTimelock) public {
        require(msg.sender == admin);

        nextTimelock = newTimelock;
        timelockUpdateReadyAt = uint64(timelock + block.timestamp);

        emit QueueTimelockUpdate(newTimelock);
    }

    /// @notice Finalizes a timelock update.
    /// @dev Throws if timelock update is not ready.
    function finalizeTimelockUpdate() public {
        require(msg.sender == admin);
        require(block.timestamp >= timelockUpdateReadyAt);

        timelock = nextTimelock;
        delete nextTimelock;
        delete timelockUpdateReadyAt;

        emit FinalizeTimelockUpdate();
    }
}
