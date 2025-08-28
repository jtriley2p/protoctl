// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Proxy1967 } from "src/Proxy/Proxy1967.sol";
import { BeaconProxy1967 } from "src/Proxy/BeaconProxy1967.sol";

uint256 constant setImplementationSelector = 0xd784d42600000000000000000000000000000000000000000000000000000000;
uint256 constant setBeaconSelector = 0xd42afb5600000000000000000000000000000000000000000000000000000000;
uint256 constant sendAdminSelector = 0xe0d7560a00000000000000000000000000000000000000000000000000000000;
uint256 constant receiveAdminSelector = 0x7f36d2e100000000000000000000000000000000000000000000000000000000;
uint256 constant rollBackSelector = 0xe080b04000000000000000000000000000000000000000000000000000000000;

// operation ::=
//     | (<createProxy> . <salt>)
//     | (<createBeaconProxy> . <salt>)
//     | (<setImplementation> . <proxy> . <impl>)
//     | (<setBeacon> . <proxy> . <beacon>)
//     | (<sendAdmin> . <proxy> . <admin>)
//     | (<receiveAdmin> . <proxy>)
//     | (<call> . <target> . <value> . <payload>)
//     | (<create2> . <salt> . <initcode>);

enum Op {
    Halt,
    CreateProxy,
    CreateBeaconProxy,
    SetImplementation,
    SetBeacon,
    SendAdmin,
    ReceiveAdmin,
    Call,
    Create2
}

type Ptr is uint256;

using {
    readOp,
    createProxy,
    createBeaconProxy,
    setImplementation,
    setBeacon,
    sendAdmin,
    receiveAdmin,
    runCall,
    runCreate2
} for Ptr global;

function readOp(Ptr ptr) pure returns (Ptr newPtr, Op op) {
    assembly {
        newPtr := add(0x01, ptr)

        op := shr(0xf8, mload(ptr))
    }
}

function createProxy(Ptr ptr) returns (Ptr newPtr) {
    bytes32 salt;

    assembly {
        salt := mload(ptr)

        newPtr := add(0x20, ptr)
    }

    new Proxy1967{salt:salt}();
}

function createBeaconProxy(Ptr ptr) returns (Ptr newPtr) {
    bytes32 salt;

    assembly {
        salt := mload(ptr)

        newPtr := add(0x20, ptr)
    }

    new BeaconProxy1967{salt:salt}();
}

function setImplementation(Ptr ptr) returns (Ptr newPtr) {
    assembly {
        let proxy := shr(0x60, mload(ptr))

        ptr := add(0x14, ptr)

        let implementation := shr(0x60, mload(ptr))

        newPtr := add(0x14, ptr)

        mstore(0x00, setImplementationSelector)
        
        mstore(0x04, implementation)

        let ok := call(gas(), proxy, 0x00, 0x00, 0x24, 0x00, 0x00)

        if iszero(ok) {
            revert(0x00, 0x00)
        }
    }
}

function setBeacon(Ptr ptr) returns (Ptr newPtr) {
    assembly {
        let proxy := shr(0x60, mload(ptr))

        ptr := add(0x14, ptr)

        let beacon := shr(0x60, mload(ptr))

        newPtr := add(0x14, ptr)

        mstore(0x00, setBeaconSelector)
        
        mstore(0x04, beacon)

        let ok := call(gas(), proxy, 0x00, 0x00, 0x24, 0x00, 0x00)

        if iszero(ok) {
            revert(0x00, 0x00)
        }
    }
}

function sendAdmin(Ptr ptr) returns (Ptr newPtr) {
    assembly {
        let proxy := shr(0x60, mload(ptr))

        ptr := add(0x14, ptr)

        let admin := shr(0x60, mload(ptr))

        newPtr := add(0x14, ptr)

        mstore(0x00, sendAdminSelector)
        
        mstore(0x04, admin)

        let ok := call(gas(), proxy, 0x00, 0x00, 0x24, 0x00, 0x00)

        if iszero(ok) {
            revert(0x00, 0x00)
        }
    }
}

function receiveAdmin(Ptr ptr) returns (Ptr newPtr) {
    assembly {
        let proxy := shr(0x60, mload(ptr))

        newPtr := add(0x14, ptr)

        mstore(0x00, receiveAdminSelector)

        let ok := call(gas(), proxy, 0x00, 0x00, 0x04, 0x00, 0x00)

        if iszero(ok) {
            revert(0x00, 0x00)
        }
    }
}

function runCall(Ptr ptr) returns (Ptr newPtr) {
    assembly {
        let target := shr(0x60, mload(ptr))

        ptr := add(0x14, ptr)

        let value := shr(0x80, mload(ptr))

        ptr := add(0x10, ptr)

        let len := shr(0xe0, mload(ptr))

        ptr := add(0x04, ptr)

        let ok := call(gas(), target, value, ptr, len, 0x00, 0x00)

        newPtr := add(ptr, len)

        if iszero(ok) {
            revert(0x00, 0x00)
        }
    }
}

function runCreate2(Ptr ptr) returns (Ptr newPtr) {
    assembly {
        let value := shr(0x80, mload(ptr))

        ptr := add(0x10, ptr)

        let salt := mload(ptr)

        ptr := add(0x20, ptr)

        let len := shr(0xe0, mload(ptr))

        ptr := add(0x04, ptr)

        let addr := create2(value, ptr, len, salt)

        newPtr := add(ptr, len)

        if iszero(addr) {
            revert(0x00, 0x00)
        }
    }
}

library ProtocolControllerVM {
    function run(bytes memory bytecode) internal {
        Ptr ptr;

        assembly {
            ptr := add(0x20, bytecode)
        }

        while (true) {
            Op op;

            (ptr, op) = ptr.readOp();

            if (op == Op.Halt) {
                break;
            } else if (op == Op.CreateProxy) {
                ptr = ptr.createProxy();
            } else if (op == Op.CreateBeaconProxy) {
                ptr = ptr.createBeaconProxy();
            } else if (op == Op.SetImplementation) {
                ptr = ptr.setImplementation();
            } else if (op == Op.SetBeacon) {
                ptr = ptr.setBeacon();
            } else if (op == Op.SendAdmin) {
                ptr = ptr.sendAdmin();
            } else if (op == Op.ReceiveAdmin) {
                ptr = ptr.receiveAdmin();
            } else if (op == Op.Call) {
                ptr = ptr.runCall();
            } else if (op == Op.Create2) {
                ptr = ptr.runCreate2();
            } else {
                revert();
            }
        }
    }
}
