// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IMintStrategy {
    enum StrategyStatus {
        Close, // 0
        Open // 1

    }

    function getWithdrawalDelayBlocks() external view returns (uint256);
    function deposit(address _token, address _user, uint256 _amount) external returns (uint256);
    function withdraw(address _token, address _user, uint256 _amount) external;

    event DepositStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event WithdrawalStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event ObeliskNetworkChanged(address obeliskNetwork, address _obeliskNetwork);
    event FundVaultChanged(address fundVault, address _fundVault);
    event Withdrawal(address _strategy, address _underlyingToken, address _user, uint256 _amount);
    event Deposit(address _strategy, address _underlyingToken, address _user, uint256 _amount);
    event UnderlyingTokenTransfer(address _to, uint256 _amount);
}
