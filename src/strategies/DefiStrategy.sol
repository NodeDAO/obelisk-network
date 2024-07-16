// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/strategies/BaseStrategy.sol";

contract DefiStrategy is BaseStrategy {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _ownerAddr,
        address _dao,
        address _strategyManager,
        address _fundManager,
        address _fundVault,
        uint256 _floorAmount,
        address _underlyingToken,
        address _strategyToken
    ) public initializer {
        __BaseStrategy_init(
            _ownerAddr,
            _dao,
            _strategyManager,
            _fundManager,
            _fundVault,
            _floorAmount,
            _underlyingToken,
            _strategyToken,
            StrategyStatus.Open,
            StrategyStatus.Close
        );
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("DefiStrategy");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }
}
