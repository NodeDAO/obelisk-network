// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "src/interfaces/IMintStrategy.sol";
import "src/interfaces/IERC20Decimal.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract MintStrategy is Initializable, Version, Dao, IMintStrategy {
    using SafeERC20 for IERC20;

    IERC20 public underlyingToken;
    address public assetAddr;

    address public obeliskNetwork;
    address public fundVault;

    StrategyStatus internal depositStatus;
    StrategyStatus internal withdrawStatus;

    uint256 internal withdrawalDelayBlocks;

    modifier onlyObeliskNetwork() {
        if (msg.sender != obeliskNetwork) revert Errors.PermissionDenied();
        _;
    }

    modifier assetCheck(address _token) {
        if (assetAddr != _token) revert Errors.AssetDismatch();
        _;
    }

    function initialize(
        address _ownerAddr,
        address _dao,
        address _obeliskNetwork,
        address _fundVault,
        address _underlyingToken,
        address _assetAddr,
        uint256 _withdrawalDelayBlocks
    ) public initializer {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);

        obeliskNetwork = _obeliskNetwork;
        fundVault = _fundVault;

        underlyingToken = IERC20(_underlyingToken);
        assetAddr = _assetAddr;

        withdrawalDelayBlocks = _withdrawalDelayBlocks;
        depositStatus = StrategyStatus.Open;
        withdrawStatus = StrategyStatus.Close;
    }

    function getWithdrawalDelayBlocks() external view returns (uint256) {
        return withdrawalDelayBlocks;
    }

    function convertAmount(uint256 amount, uint8 sourceDecimals, uint8 targetDecimals) public pure returns (uint256) {
        if (sourceDecimals == targetDecimals) {
            return amount;
        } else if (sourceDecimals > targetDecimals) {
            return amount / 10 ** (sourceDecimals - targetDecimals);
        } else {
            return amount * 10 ** (targetDecimals - sourceDecimals);
        }
    }

    function deposit(address _token, address _user, uint256 _amount)
        external
        onlyObeliskNetwork
        assetCheck(_token)
        returns (uint256)
    {
        if (depositStatus != StrategyStatus.Open) {
            revert Errors.DepositNotOpen();
        }

        uint8 sourceDecimals = IERC20Decimal(address(underlyingToken)).decimals();
        uint8 targetDecimals = IERC20Decimal(address(assetAddr)).decimals();

        uint256 _mintAmount = convertAmount(_amount, sourceDecimals, targetDecimals);
        uint256 _depositAmount = convertAmount(_mintAmount, targetDecimals, sourceDecimals);

        _deposit(_user, _depositAmount);

        emit Deposit(address(this), address(underlyingToken), _user, _depositAmount);
        return _mintAmount;
    }

    function withdraw(address _token, address _user, uint256 _amount)
        external
        virtual
        onlyObeliskNetwork
        assetCheck(_token)
    {
        if (withdrawStatus != StrategyStatus.Open) {
            revert Errors.WithdrawalNotOpen();
        }
        uint8 targetDecimals = IERC20Decimal(address(underlyingToken)).decimals();
        uint8 sourceDecimals = IERC20Decimal(address(assetAddr)).decimals();
        uint256 _transferAmount = convertAmount(_amount, sourceDecimals, targetDecimals);

        _withdrawal(_user, _transferAmount);
        emit Withdrawal(address(this), address(underlyingToken), _user, _transferAmount);
    }

    function _deposit(address _user, uint256 _amount) internal {
        underlyingToken.safeTransferFrom(_user, address(this), _amount);
    }

    function _withdrawal(address _user, uint256 _amountToSend) internal {
        underlyingToken.safeTransfer(_user, _amountToSend);
    }

    function operatingUnderlyingToken(uint256 _amount) external onlyDao {
        address _to = fundVault;
        underlyingToken.safeTransfer(_to, _amount);
        emit UnderlyingTokenTransfer(_to, _amount);
    }

    function setStrategyStatus(StrategyStatus _depositStatus, StrategyStatus _withdrawStatus) external onlyDao {
        if (_depositStatus != depositStatus) {
            emit DepositStatusChanged(depositStatus, _depositStatus);
            depositStatus = _depositStatus;
        }
        if (_withdrawStatus != withdrawStatus) {
            emit WithdrawalStatusChanged(withdrawStatus, _withdrawStatus);
            withdrawStatus = _withdrawStatus;
        }
    }

    function getStrategyStatus() public view returns (StrategyStatus _depositStatus, StrategyStatus _withdrawStatus) {
        return (depositStatus, withdrawStatus);
    }

    function setFundVault(address _fundVault) external onlyDao {
        emit FundVaultChanged(fundVault, _fundVault);
        fundVault = _fundVault;
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("MintStrategy");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }
}
