// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IObeliskNetwork {
    function mint(address token, address to, uint256 mintAmount) external;
}
