// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IBaseToken.sol";
import "src/interfaces/IFundRecovery.sol";

abstract contract FundRecovery is IFundRecovery {
    struct RecoveryInfo {
        address from;
        address to;
        address token;
        uint32 executed;
        uint96 requestHeight;
        uint128 requestAmount;
    }

    uint256 public constant recoveryDelayBlocks = 50400;

    RecoveryInfo[] public recoveryQueue;

    function getUserRecoverys(address _receiver) public view returns (RecoveryInfo[] memory) {
        uint256 counts = 0;
        for (uint256 i = 0; i < recoveryQueue.length; ++i) {
            if (recoveryQueue[i].to == _receiver) {
                counts++;
            }
        }

        RecoveryInfo[] memory userRecoverys = new RecoveryInfo[](counts);
        uint256 index = 0;
        for (uint256 i = 0; i < recoveryQueue.length; ++i) {
            if (recoveryQueue[i].to == _receiver) {
                userRecoverys[index] = recoveryQueue[i];
            }
        }

        return userRecoverys;
    }

    function _initiateFundRecovery(address _from, address _to, address _token, uint256 _amount) internal {
        recoveryQueue.push(
            RecoveryInfo({
                from: _from,
                to: _to,
                token: _token,
                executed: 0,
                requestHeight: uint32(block.number),
                requestAmount: uint128(_amount)
            })
        );

        emit FundRecoveryInitiated(_from, _to, _token, _amount);
    }

    function _executeFundRecovery(uint256 _requestId) internal {
        RecoveryInfo memory recovery = recoveryQueue[_requestId];
        if (recovery.requestHeight + recoveryDelayBlocks > block.number || recovery.executed != 0) {
            revert Errors.InvalidRequestId();
        }

        recoveryQueue[_requestId].executed = 1;

        IBaseToken(recovery.token).whiteListBurn(uint256(recovery.requestAmount), recovery.from);
        IBaseToken(recovery.token).whiteListMint(uint256(recovery.requestAmount), recovery.to);

        emit FundRecoveryExecuted(recovery.from, recovery.to, recovery.requestAmount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
