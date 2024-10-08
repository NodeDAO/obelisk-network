// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/strategies/BaseStrategy.sol";

contract CefiStrategy is BaseStrategy {
    mapping(address => uint256) public pendingWithdrawal;
    uint256 public totalPendingWithdrawal;

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
            StrategyStatus.Open
        );
    }

    function requestWithdrawal(address _user, uint256 _amount) external override onlyStrategyManager {
        if (status != StrategyStatus.Open) {
            revert Errors.CantRequestWithdrawal();
        }

        pendingWithdrawal[_user] += _amount;
        totalPendingWithdrawal += _amount;
        emit RequestWithdrawal(address(this), _user, _amount);
    }

    function withdraw(address _user, uint256 _amount) external override onlyStrategyManager {
        StrategyStatus _status = status;
        if (_status == StrategyStatus.Close) {
            _withdraw(_user, _amount);
            return;
        }

        if (_status == StrategyStatus.Open) {
            revert Errors.NoRedeemable();
        }

        if (pendingWithdrawal[_user] == 0) {
            revert Errors.NoWithdrawalRequested();
        }

        _withdraw(_user, _amount);
        pendingWithdrawal[_user] -= _amount;
        totalPendingWithdrawal -= _amount;
    }

    function operatingUnderlyingToken(uint256 _amount) external onlyFundManager {
        address _to = fundVault;
        underlyingToken.transfer(_to, _amount);
        emit UnderlyingTokenTransfer(_to, _amount);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("CefiStrategy");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }
}
