/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./JOJOStorage.sol";
import "../utils/Errors.sol";
import "../lib/Liquidation.sol";
import "../lib/Funding.sol";
import "../lib/Trading.sol";

contract JOJOExternal is JOJOStorage {
    using SafeERC20 for IERC20;

    function deposit(uint256 amount, address to) external nonReentrant {
        Funding._deposit(state, amount, to);
    }

    function withdraw(uint256 amount, address to) external nonReentrant {
        Funding._withdraw(state, amount, to);
    }

    function withdrawPendingFund(address to) external nonReentrant {
        Funding._withdrawPendingFund(state, to);
    }

    function approveTrade(address orderSender, bytes calldata tradeData)
        external
        returns (
            address[] memory, // traderList
            int256[] memory, // paperChangeList
            int256[] memory // creditChangeList
        )
    {
        Types.MatchResult memory result = Trading._approveTrade(
            state,
            orderSender,
            tradeData
        );
        return (
            result.traderList,
            result.paperChangeList,
            result.creditChangeList
        );
    }

    function isSafe(address trader) external view returns (bool safe) {
        return Liquidation._isSafe(state, trader);
    }

    function requestLiquidate(
        address liquidatedTrader,
        uint256 requestPaperAmount
    )
        external
        returns (
            int256 liquidatorPaperChange,
            int256 liquidatorCreditChange,
            int256 ltPaperChange,
            int256 ltCreditChange
        )
    {
        uint256 insuranceFee;
        (ltPaperChange, ltCreditChange, insuranceFee) = Liquidation
            ._getLiquidateCreditAmount(
                state,
                liquidatedTrader,
                requestPaperAmount
            );
        state.trueCredit[state.insurance] += int256(insuranceFee);
        liquidatorCreditChange = ltCreditChange * -1;
        liquidatorPaperChange = ltPaperChange * -1;
        ltCreditChange -= int256(insuranceFee);
    }

    function positionClear(address trader) external {
        Liquidation._positionClear(state, trader);
    }
}
