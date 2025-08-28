// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Administrated } from "src/Auth/Administrated.sol";

/// @title Beacon Example
/// @author jtriley2p
/// @notice Minimalist beacon contract with single-authenticated address.
contract Beacon is Administrated {
    /// @notice Logged when implementation is set.
    /// @param newImplementation New implementation address.
    event ImplementationSet(address indexed newImplementation);

    /// @notice Returns the implementation address.
    address public implementation;

    /// @notice Sets the new implementation address.
    /// @param newImplementation New implementation address.
    function setImplementation(
        address newImplementation
    ) public {
        require(msg.sender == admin);

        implementation = newImplementation;

        emit ImplementationSet(newImplementation);
    }
}
