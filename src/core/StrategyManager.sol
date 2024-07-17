// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "src/modules/Strategy.sol";
import "src/interfaces/IStrategyManager.sol";
import "src/interfaces/IBaseStrategy.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract StrategyManager is Initializable, Version, Dao, Strategy, IStrategyManager {
    constructor() {
        _disableInitializers();
    }

    function initialize(address _ownerAddr, address _dao, address[] calldata _strategies) public initializer {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);
        __Strategy_init(_strategies);
    }

    function getStakerStrategyList(address _user) public view returns (address[] memory, uint256[] memory) {
        uint256 _strategyListength = strategyList.length;
        uint256[] memory _sharesList = new uint256[](_strategyListength);
        uint256 _number = 0;
        for (uint256 i = 0; i < _strategyListength;) {
            uint256 _share = IBaseStrategy(strategyList[i]).getUserShares(_user);
            if (_share != 0) {
                _number++;
            }

            _sharesList[i] = _share;
            unchecked {
                ++i;
            }
        }
        address[] memory strategies = new address[](_number);
        uint256[] memory _shares = new uint256[](_number);
        uint256 j = 0;
        for (uint256 i = 0; i < _strategyListength;) {
            if (_sharesList[i] != 0) {
                strategies[j] = strategyList[i];
                _shares[j] = _sharesList[i];
                j++;
            }
        }

        return (strategies, _shares);
    }

    function addStrategies(address[] calldata _strategies) external onlyDao {
        _addStrategies(_strategies);
    }

    function removeStrategies(address[] calldata _strategies) external onlyDao {
        _removeStrategies(_strategies);
    }

    function deposit(address _strategy, uint256 _amount) external whenNotPaused nonReentrant {
        _checkStrategiesWhitelisted(_strategy);
        IBaseStrategy(_strategy).deposit(msg.sender, _amount);
        emit UserDeposit(_strategy, msg.sender, _amount, block.number);
    }

    function requestWithdrawal(address _strategy, uint256 _amount) external whenNotPaused nonReentrant {
        _checkStrategiesWhitelisted(_strategy);
        IBaseStrategy(_strategy).requestWithdrawal(msg.sender, _amount);
        emit UserWithdrawal(_strategy, msg.sender, _amount, block.number);
    }

    function withdraw(address _strategy, uint256 _amount) external whenNotPaused nonReentrant {
        _checkStrategiesWhitelisted(_strategy);
        IBaseStrategy(_strategy).withdraw(msg.sender, _amount);
        emit UserRequestWithdrawal(_strategy, msg.sender, _amount, block.number);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("StrategyManager");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }

    /**
     * @notice stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice start protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }
}
