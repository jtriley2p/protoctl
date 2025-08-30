// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Lockdown} from "src/Auth/Lockdown.sol";

/// @title Administrated Contract
/// @author jtriley2p
/// @notice Simple, single authorized address abstract contract. Transition requires two steps;
///         current admin sends authorization to new admin, new admin accepts authorization. This
///         requires the new be capable of calling this contract before transition, preventing
///         bricking.
/// @notice Inherits `Lockdown` to ensure _all_ admin functions can be locked down.
abstract contract Administrated is Lockdown {
    /// @notice Logged when admin authority is sent.
    /// @param newAdmin New admin address.
    event SendAdmin(address indexed newAdmin);

    /// @notice Logged when admin authority is received.
    event ReceiveAdmin();

    /// @notice Current admin address.
    address public admin;

    /// @notice Pending admin address
    /// @dev Address is non-zero only between sending and receiving admin.
    address public pendingAdmin;

    /// @notice Sends admin authority.
    /// @param newAdmin New admin address.
    function sendAdmin(address newAdmin) public {
        require(msg.sender == admin);
        require(!inLockdown());

        pendingAdmin = newAdmin;

        emit SendAdmin(newAdmin);
    }

    /// @notice Receives admin authority.
    function receiveAdmin() public {
        require(msg.sender == pendingAdmin);
        require(!inLockdown());

        admin = msg.sender;

        delete pendingAdmin;

        emit ReceiveAdmin();
    }
}
