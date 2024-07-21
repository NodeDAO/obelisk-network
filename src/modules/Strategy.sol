// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IStrategy.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Strategy Management
 * @author Obelisk
 * @notice Provides management strategy functions
 */
abstract contract Strategy is Initializable, IStrategy {
    mapping(address => bool) public strategyIsWhitelisted;
    address[] internal strategyList;

    function _checkStrategiesWhitelisted(address _strategy) internal view {
        if (!strategyIsWhitelisted[_strategy]) revert Errors.StrategyNotWhitelisted();
    }

    function __Strategy_init(address[] calldata _strategies) internal onlyInitializing {
        uint256 strategiesLength = _strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            strategyIsWhitelisted[_strategies[i]] = true;
            strategyList.push(_strategies[i]);
            emit StrategyAddedToWhitelist(_strategies[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getStrategyList() public view returns (address[] memory) {
        return strategyList;
    }

    function _addStrategies(address[] calldata _strategies) internal {
        uint256 strategiesLength = _strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            if (!strategyIsWhitelisted[_strategies[i]]) {
                strategyIsWhitelisted[_strategies[i]] = true;
                strategyList.push(_strategies[i]);
                emit StrategyAddedToWhitelist(_strategies[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _removeStrategies(address[] calldata _strategies) internal {
        uint256 strategiesLength = _strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            if (strategyIsWhitelisted[_strategies[i]]) {
                strategyIsWhitelisted[_strategies[i]] = false;
                _removeStrategyList(_strategies[i]);
                emit StrategyRemovedFromWhitelist(_strategies[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _removeStrategyList(address _strategy) internal {
        uint256 _strategyListength = strategyList.length;
        for (uint256 i = 0; i < _strategyListength;) {
            if (strategyList[i] == _strategy) {
                strategyList[i] = strategyList[_strategyListength - 1];
                strategyList.pop();
                return;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
