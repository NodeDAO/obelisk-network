// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface ImmutableCreate2Factory {
    function safeCreate2(bytes32 salt, bytes calldata initializationCode)
        external
        payable
        returns (address deploymentAddress);
}
