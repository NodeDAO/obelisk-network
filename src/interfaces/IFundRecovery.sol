// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IFundRecovery {
    event FundRecoveryInitiated(address _from, address _to, address _token, uint256 _amount);
    event FundRecoveryExecuted(address _from, address _to, uint256 _amount);
}
