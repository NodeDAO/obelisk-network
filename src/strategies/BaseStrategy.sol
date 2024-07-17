// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "src/interfaces/IBaseToken.sol";
import "src/interfaces/IBaseStrategy.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract BaseStrategy is Initializable, Version, Dao, IBaseStrategy {
    using SafeERC20 for IERC20;

    address public strategyManager;

    address public fundVault;
    address public fundManager;
    uint256 public floorAmount;

    StrategyStatus internal depositStatus;
    StrategyStatus internal withdrawStatus;

    IERC20 public underlyingToken;

    address public strategyToken;
    mapping(address => uint256) internal userShares;
    uint256 public totalShares;

    modifier onlyStrategyManager() {
        if (msg.sender != strategyManager) revert Errors.PermissionDenied();
        _;
    }

    modifier onlyFundManager() {
        if (msg.sender != fundManager) revert Errors.PermissionDenied();
        _;
    }

    function __BaseStrategy_init(
        address _ownerAddr,
        address _dao,
        address _strategyManager,
        address _fundManager,
        address _fundVault,
        uint256 _floorAmount,
        address _underlyingToken,
        address _strategyToken,
        StrategyStatus _depositStatus,
        StrategyStatus _withdrawStatus
    ) internal onlyInitializing {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);
        strategyManager = _strategyManager;
        fundManager = _fundManager;
        fundVault = _fundVault;
        floorAmount = _floorAmount;
        underlyingToken = IERC20(_underlyingToken);
        if (_strategyToken != address(0)) {
            strategyToken = _strategyToken;
        }
        depositStatus = _depositStatus;
        withdrawStatus = _withdrawStatus;
    }

    function getStrategyStatus() public view returns (StrategyStatus _depositStatus, StrategyStatus _withdrawStatus) {
        return (depositStatus, withdrawStatus);
    }

    function setStrategyStatus(StrategyStatus _depositStatus, StrategyStatus _withdrawStatus)
        external
        onlyFundManager
    {
        if (_depositStatus != depositStatus) {
            emit DepositStatusChanged(depositStatus, _depositStatus);
            depositStatus = _depositStatus;
        }
        if (_withdrawStatus != withdrawStatus) {
            emit WithdrawalStatusChanged(withdrawStatus, _withdrawStatus);
            withdrawStatus = _withdrawStatus;
        }
    }

    function setStrategySetting(
        address _strategyManager,
        address _fundManager,
        address _fundVault,
        uint256 _floorAmount
    ) external onlyDao {
        if (_strategyManager != address(0)) {
            emit StrategyManagerChanged(strategyManager, _strategyManager);
            strategyManager = _strategyManager;
        }
        if (_fundManager != address(0)) {
            emit FundManagerChanged(fundManager, _fundManager);
            fundManager = _fundManager;
        }
        if (_fundVault != address(0)) {
            emit FundVaultChanged(fundVault, _fundVault);
            fundVault = _fundVault;
        }
        if (_floorAmount != 0) {
            emit FloorAmountChanged(floorAmount, _floorAmount);
            floorAmount = _floorAmount;
        }
    }

    function deposit(address _user, uint256 _amount) external onlyStrategyManager {
        if (_amount < floorAmount) {
            revert Errors.InvalidAmount();
        }
        if (depositStatus != StrategyStatus.Open) {
            revert Errors.DepositNotOpen();
        }

        _beforeDeposit(_user, _amount);
        _addShares(_user, _amount);

        emit Deposit(address(this), _user, _amount);
    }

    function requestWithdrawal(address _user, uint256 _amount) external virtual onlyStrategyManager {
        if (withdrawStatus != StrategyStatus.Open) {
            revert Errors.WithdrawalNotOpen();
        }

        _withdraw(_user, _amount);
    }

    function withdraw(address _user, uint256 _amount) external virtual onlyStrategyManager {
        if (withdrawStatus != StrategyStatus.Open) {
            revert Errors.WithdrawalNotOpen();
        }

        _withdraw(_user, _amount);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        _removeShares(_user, _amount);
        _transfer(_user, _amount);
        emit Withdrawal(address(this), _user, _amount);
    }

    function _beforeDeposit(address _user, uint256 _amount) internal {
        underlyingToken.safeTransferFrom(_user, address(this), _amount);
    }

    function _transfer(address _user, uint256 _amountToSend) internal {
        underlyingToken.safeTransfer(_user, _amountToSend);
    }

    function _addShares(address _user, uint256 _amount) internal {
        totalShares += _amount;

        if (strategyToken == address(0)) {
            userShares[_user] += _amount;
            return;
        }

        IBaseToken(strategyToken).whiteListMint(_amount, _user);
    }

    function _removeShares(address _user, uint256 _amount) internal {
        totalShares -= _amount;

        if (strategyToken == address(0)) {
            userShares[_user] -= _amount;
            return;
        }

        IBaseToken(strategyToken).whiteListBurn(_amount, _user);
    }

    function getUserShares(address _user) external view returns (uint256) {
        if (strategyToken == address(0)) {
            return userShares[_user];
        }

        return IERC20(strategyToken).balanceOf(_user);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
