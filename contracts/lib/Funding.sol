/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../intf/IPerpetual.sol";
import "../intf/IMarkPriceSource.sol";
import "../utils/SignedDecimalMath.sol";
import "../utils/Errors.sol";
import "./Liquidation.sol";
import "./Types.sol";

library Funding {
    using SafeERC20 for IERC20;

    function _deposit(
        Types.State storage state,
        uint256 amount,
        address to
    ) internal {
        IERC20(state.underlyingAsset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        state.trueCredit[to] += int256(amount);
    }

    function _withdraw(
        Types.State storage state,
        uint256 amount,
        address to
    ) internal {
        require(
            state.trueCredit[msg.sender] >= int256(amount),
            Errors.CREDIT_NOT_ENOUGH
        );
        if (state.withdrawTimeLock == 0) {
            _settleWithdraw(state, msg.sender, to, amount);
        } else {
            state.pendingWithdraw[msg.sender] = amount;
            state.requestWithdrawTimestamp[msg.sender] = block.timestamp;
        }
    }

    function _withdrawPendingFund(Types.State storage state, address to)
        internal
    {
        require(
            state.requestWithdrawTimestamp[msg.sender] +
                state.withdrawTimeLock <=
                block.timestamp,
            Errors.WITHDRAW_PENDING
        );
        uint256 amount = state.requestWithdrawTimestamp[msg.sender];
        _settleWithdraw(state, msg.sender, to, amount);
        state.pendingWithdraw[msg.sender] = 0;
    }

    function _settleWithdraw(
        Types.State storage state,
        address payer,
        address to,
        uint256 amount
    ) internal {
        state.trueCredit[payer] -= int256(amount);
        IERC20(state.underlyingAsset).safeTransfer(to, amount);

        require(Liquidation._isSafe(state, payer), Errors.ACCOUNT_NOT_SAFE);
    }
}
