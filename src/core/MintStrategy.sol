// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "src/modules/Whitelisted.sol";
import "src/modules/Call.sol";
import "src/interfaces/IMintStrategy.sol";
import "src/interfaces/IERC20Decimal.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Mint OBTC Strategy
 * @author Obelisk
 * @notice Receive ERC20 BTC assets to mint OBTC
 */
contract MintStrategy is Initializable, Version, Dao, Whitelisted, Call, IMintStrategy {
    using SafeERC20 for IERC20;

    // ERC20 BTC asset address
    IERC20 public underlyingToken;
    // OBTC asset address
    address public assetAddr;

    address public obeliskNetwork;

    StrategyStatus internal depositStatus;
    StrategyStatus internal withdrawStatus;

    // Withdrawal delay
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
        address _underlyingToken,
        address _assetAddr,
        uint256 _withdrawalDelayBlocks
    ) public initializer {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);

        obeliskNetwork = _obeliskNetwork;

        underlyingToken = IERC20(_underlyingToken);
        assetAddr = _assetAddr;

        withdrawalDelayBlocks = _withdrawalDelayBlocks;
        // Withdrawal is not enabled by default
        depositStatus = StrategyStatus.Open;
        withdrawStatus = StrategyStatus.Close;
    }

    /**
     * Get withdrawal delay for strategy
     * @return _withdrawalDelayBlocks
     */
    function getWithdrawalDelayBlocks() external view returns (uint256) {
        return withdrawalDelayBlocks;
    }

    /**
     * Amounts are calculated based on the precision of different tokens to ensure 1:1
     * @param amount amount
     * @param sourceDecimals  source token decimals
     * @param targetDecimals  target token decimals
     */
    function convertAmount(uint256 amount, uint8 sourceDecimals, uint8 targetDecimals) public pure returns (uint256) {
        if (sourceDecimals == targetDecimals) {
            return amount;
        } else if (sourceDecimals > targetDecimals) {
            return amount / 10 ** (sourceDecimals - targetDecimals);
        } else {
            return amount * 10 ** (targetDecimals - sourceDecimals);
        }
    }

    /**
     * Transfer user deposit assets
     * Check whether the deposited token is consistent with the minted token of the strategy
     * @param _token token address,such as: oBTC addr
     * @param _user user addr
     * @param _amount deposit amount
     */
    function deposit(address _token, address _user, uint256 _amount)
        external
        onlyObeliskNetwork
        assetCheck(_token)
        returns (uint256)
    {
        if (depositStatus != StrategyStatus.Open) {
            revert Errors.DepositNotOpen();
        }

        // The erc20 asset must implement the decimals method, which involves mapping between assets of different decimals
        uint8 sourceDecimals = IERC20Decimal(address(underlyingToken)).decimals();
        uint8 targetDecimals = IERC20Decimal(address(assetAddr)).decimals();

        // Calculate the number of tokens that should be minted based on the precision
        uint256 _mintAmount = convertAmount(_amount, sourceDecimals, targetDecimals);
        // Ensure there is no loss of accuracy and calculate the user's deposit amount
        uint256 _depositAmount = convertAmount(_mintAmount, targetDecimals, sourceDecimals);

        _deposit(_user, _depositAmount);

        emit Deposit(address(this), address(underlyingToken), _user, _depositAmount);
        return _mintAmount;
    }

    /**
     * User Withdrawal
     * Check whether the withdrawal token is consistent with the strategy's burn token
     * @param _token token address,such as: oBTC addr
     * @param _user user address
     * @param _amount withdrawal amount
     */
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
        // Calculate the amount that users can withdraw based on the precision
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

    /**
     * The _to parameter must be pre-set to a whitelist.
     * Used for fund transfer between DeFi protocols without the need for intermediate account.
     */
    function execute(uint256 _value, address _to, bytes memory _data, uint256 _txGas) external onlyDao {
        _checkWhitelisted(_to);
        _execute(_value, _to, _data, _txGas);
        emit TxExecuted(_value, _to, _data);
    }

    /**
     * Add deposit strategy
     * @param _strategies deposit strategies
     */
    function addWhitelisted(address[] calldata _strategies) external onlyDao {
        _addWhitelisted(_strategies);
    }

    /**
     * Remove strategy
     * @param _strategies deposit strategies
     */
    function removeWhitelisted(address[] calldata _strategies) external onlyDao {
        _removeWhitelisted(_strategies);
    }

    /**
     * setStrategyStatus
     * @param _depositStatus deposit status
     * @param _withdrawStatus  withdrawal status
     */
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

    /**
     * Get the deposit and withdrawal status of the strategy
     * @return _depositStatus
     * @return _withdrawStatus
     */
    function getStrategyStatus() public view returns (StrategyStatus _depositStatus, StrategyStatus _withdrawStatus) {
        return (depositStatus, withdrawStatus);
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
