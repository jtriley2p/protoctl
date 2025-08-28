// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Administrated1967, adminSlot} from "src/Auth/Administrated1967.sol";

bytes32 constant beaconSlot = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

/// @title Beacon Proxy
/// @author jtriley2p
/// @notice Beacon contract for ERC-1967 BeaconProxy contracts to call for the implementation
///         address.
contract BeaconProxy1967 is Administrated1967 {
    /// @notice Logged on beacon set.
    /// @param beacon New beacon contract address.
    /// @dev Note that this is when the beacon itself changes, not the address it returns.
    event BeaconSet(address indexed beacon);

    constructor() {
        assembly {
            sstore(adminSlot, caller())
        }

        emit AdminChanged(msg.sender);
    }

    /// @notice Returns beacon address.
    function beacon() public view returns (address bcn) {
        assembly {
            bcn := sload(beaconSlot)
        }
    }

    /// @notice Sets beacon contract address.
    /// @param newBeacon New beacon contract address.
    /// @dev Note that this changes the beacon itself changes, not the address it returns.
    function setBeacon(address newBeacon) public {
        require(msg.sender == admin());

        assembly {
            sstore(beaconSlot, newBeacon)
        }

        emit BeaconSet(newBeacon);
    }
}
