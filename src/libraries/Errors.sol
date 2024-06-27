// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

library Errors {
    error PermissionDenied();
    error InvalidAddr();
    error InvalidVersion();
    error InvalidtypeId();
    error InvalidParameter();
    error InvalidAmount();
    error UpdateTimelocked();
    error InvalidLength();
    error InvalidRequestId();
    error ClaimTooEarly();
    error DelayTooLarge();
    error BlackListed();
    error DuplicateAddress();
    error NotAGuardian();
    error InvalidSignature();
    error SignaturesNotSorted();
    error DepositNoQuorum();
    error MsgHashAlreadyMint();
    error InvalidAsset();
    error AssetNotSupported();
    error AssetPaused();
    error NoRedeemable();
    error NoWithdrawalRequested();
    error CantRequestWithdrawal();
    error StrategyClosed();
    error StrategyNotWhitelisted();
    error TransferFailed();
}
