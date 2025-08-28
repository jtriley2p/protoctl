// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {Administrated1967, adminSlot} from "src/Auth/Administrated1967.sol";

bytes32 constant implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/// @title ERC-1967 Proxy
/// @author jtriley2p
/// @notice Proxy contract implementing the ERC-1967 storage layout specification.
/// @dev The only deviation from ERC-1967 is in the event definition for changing admin addresses.
///      It has been modified because the standard uses "SHOULD" instead of "MUST" and this enables
///      two-step admin transfer.
contract Proxy1967 is Administrated1967 {
    /// @notice Logged on implementation set.
    /// @param implementation New implementation contract address.
    event ImplementationSet(address indexed implementation);

    constructor() {
        assembly {
            sstore(adminSlot, caller())
        }

        emit AdminChanged(msg.sender);
    }

    /// @notice Returns implementation contract address.
    function implementation() public view returns (address impl) {
        assembly {
            impl := sload(implSlot)
        }
    }

    /// @notice Sets the implementation contract address.
    /// @param newImplementation New implementation contract address.
    function setImplementation(address newImplementation) public {
        require(msg.sender == admin());

        assembly {
            sstore(implSlot, newImplementation)
        }

        emit ImplementationSet(newImplementation);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())

            let ok := delegatecall(gas(), sload(implSlot), 0x00, calldatasize(), 0x00, 0x00)

            returndatacopy(0x00, 0x00, returndatasize())

            if ok { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }

    receive() external payable {
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())

            let ok := delegatecall(gas(), sload(implSlot), 0x00, calldatasize(), 0x00, 0x00)

            returndatacopy(0x00, 0x00, returndatasize())

            if ok { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }
}
