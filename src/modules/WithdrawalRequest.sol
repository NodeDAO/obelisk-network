// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/BlackList.sol";
import "src/interfaces/IWithdrawalRequest.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Withdrawal request contract
 * @author NodeDAO
 * @notice Provides basic functions for withdrawal orders.
 */
abstract contract WithdrawalRequest is Initializable, BlackList, IWithdrawalRequest {
    struct WithdrawalInfo {
        uint96 withdrawalHeight;
        uint32 claimed;
        uint128 withdrawalAmount;
        address token;
        bytes withdrawalAddr;
    }

    uint256 public withdrawalDelayBlocks;
    // 10 days
    uint256 public constant MAX_WITHDRAWAL_DELAY_BLOCKS = 72000;

    mapping(address => WithdrawalInfo[]) internal withdrawalQueue;

    uint256 public totalWithdrawalAmount;

    function __WithdrawalRequest_init(uint256 _withdrawalDelayBlocks, address _blackListAdmin)
        internal
        onlyInitializing
    {
        withdrawalDelayBlocks = _withdrawalDelayBlocks;
        __BlackList_init(_blackListAdmin);
    }

    /**
     * @notice Query all withdrawals of the recipient
     * @param _receiver fund recipient
     */
    function getUserWithdrawals(address _receiver) public view returns (WithdrawalInfo[] memory) {
        return withdrawalQueue[_receiver];
    }

    /**
     * @notice Check if the withdrawal can be claimed
     * @param _receiver fund recipient
     * @param _requestId withdrawal request id
     */
    function canClaimWithdrawal(address _receiver, uint256 _requestId) public view returns (bool) {
        WithdrawalInfo[] memory _userWithdrawals = withdrawalQueue[_receiver];
        if (_requestId >= _userWithdrawals.length) {
            revert Errors.InvalidLength();
        }

        if (isBlackListed[_receiver]) {
            return false;
        }

        if (block.number < _userWithdrawals[_requestId].withdrawalHeight + withdrawalDelayBlocks) {
            return false;
        }

        return true;
    }

    /**
     * @notice Create withdrawal request
     * @param _receiver fund recipient
     * @param _withdrawalAmount withdrawal amount
     */
    function _requestWithdrawals(
        address _token,
        address _receiver,
        uint256 _withdrawalAmount,
        bytes memory _withdrawalAddr
    ) internal {
        uint256 _blockNumber = block.number;
        withdrawalQueue[_receiver].push(
            WithdrawalInfo({
                withdrawalHeight: uint96(_blockNumber),
                claimed: 0,
                withdrawalAmount: uint128(_withdrawalAmount),
                token: _token,
                withdrawalAddr: _withdrawalAddr
            })
        );
        totalWithdrawalAmount += _withdrawalAmount;
        emit WithdrawalsRequest(
            _token, _receiver, withdrawalQueue[_receiver].length - 1, _withdrawalAmount, _withdrawalAddr, _blockNumber
        );
    }

    /**
     * @notice Claim withdrawal
     * @param _receiver fund recipient
     * @param _requestId withdrawal request id
     */
    function _claimWithdrawals(address _receiver, uint256 _requestId) internal returns (uint256, address) {
        WithdrawalInfo memory _userWithdrawal = withdrawalQueue[_receiver][_requestId];
        uint256 _blockNumber = block.number;
        if (
            _userWithdrawal.withdrawalAmount == 0 || _userWithdrawal.claimed != 0 || isBlackListed[_receiver]
                || _blockNumber < _userWithdrawal.withdrawalHeight + withdrawalDelayBlocks
        ) {
            revert Errors.InvalidRequestId();
        }

        withdrawalQueue[_receiver][_requestId].claimed = 1;

        totalWithdrawalAmount -= _userWithdrawal.withdrawalAmount;
        emit WithdrawalsClaimed(
            _userWithdrawal.token,
            _receiver,
            _requestId,
            _userWithdrawal.withdrawalAmount,
            _userWithdrawal.withdrawalAddr,
            _blockNumber
        );

        return (_userWithdrawal.withdrawalAmount, _userWithdrawal.token);
    }

    /**
     * @notice update withdarawal delay block number
     * @param _withdrawalDelayBlocks new delay block number
     */
    function _setWithdrawalDelayBlocks(uint256 _withdrawalDelayBlocks) internal {
        if (_withdrawalDelayBlocks > MAX_WITHDRAWAL_DELAY_BLOCKS) {
            revert Errors.DelayTooLarge();
        }

        emit WithdrawalDelayChanged(withdrawalDelayBlocks, _withdrawalDelayBlocks);
        withdrawalDelayBlocks = _withdrawalDelayBlocks;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
