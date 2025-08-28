// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { TimelockAdministrated } from "src/Auth/TimelockAdministrated.sol";
import { ProtocolControllerVM } from "src/Lib/VM.sol";

// Deployment status
enum Status {
    Queued,
    Cancelled,
    Deployed
}

// Deployment Structure
struct Deployment {
    // Deployment status
    Status status;
    // Timestamp at which deployment may execute
    uint64 readyAt;
    // Bytecode for deployment
    bytes bytecode;
}

/// @title Protocol Controller
/// @author jtriley2p
/// @notice Controller for running deployments including proxy creation, update, and rollback ops,
///         beacon creation, update, and rollback, admin setting, arbitrary contract creation, and
///         arbitrary external call execution.
contract ProtocolController is TimelockAdministrated {
    /// @notice Logged on status update.
    /// @param index Deployment index.
    /// @param status New deployment status.
    event StatusUpdate(uint256 indexed index, Status status);

    /// @notice Archive of previous deployments.
    Deployment[] public deployments;

    /// @notice Queues a new deployment.
    /// @param bytecode Bytecode for the VM to execute when timelock is ready.
    function queue(
        bytes calldata bytecode
    ) public {
        uint256 index = deployments.length - 1;

        require(msg.sender == admin);
        require(deployments[index].status != Status.Queued);

        deployments.push(Deployment(Status.Queued, uint64(block.timestamp + timelock), bytecode));

        emit StatusUpdate(index, Status.Queued);
    }

    /// @notice Cancels a deployment.
    function cancel() public {
        uint256 index = deployments.length - 1;
        Deployment storage deployment = deployments[index];

        require(msg.sender == admin);
        require(deployment.status == Status.Queued);

        deployment.status = Status.Cancelled;

        emit StatusUpdate(index, Status.Cancelled);
    }

    /// @notice Executes a deployment.
    function execute() public {
        uint256 index = deployments.length - 1;
        Deployment storage deployment = deployments[index];

        require(msg.sender == admin);
        require(deployment.status == Status.Queued);
        require(deployment.readyAt <= block.timestamp);

        ProtocolControllerVM.run(deployment.bytecode);
    }
}
