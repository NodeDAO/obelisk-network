// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IBaseStrategy {
    enum StrategyStatus {
        Open,
        Redeemable,
        Close
    }

    function deposit(address _user, uint256 _amount) external;
    function requestWithdrawal(address _user, uint256 _amount) external;
    function withdraw(address _user, uint256 _amount) external;
    function getUserShares(address _user) external view returns (uint256);

    event StrategyStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event StrategyManagerChanged(address strategyManager, address _strategyManager);
    event FundManagerChanged(address fundManager, address _fundManager);
    event FundVaultChanged(address fundVault, address _fundVault);
    event FloorAmountChanged(uint256 floorAmount, uint256 _floorAmount);
    event Withdrawal(address _strategy, address _user, uint256 _amount);
    event RequestWithdrawal(address _strategy, address _user, uint256 _amount);
    event Deposit(address _strategy, address _user, uint256 _amount);
    event UnderlyingTokenTransfer(address _to, uint256 _amount);
}
