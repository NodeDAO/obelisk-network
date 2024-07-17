// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IStrategy {
    event StrategyAddedToWhitelist(address _strategy);
    event StrategyRemovedFromWhitelist(address _strategy);
}
