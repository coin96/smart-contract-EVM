/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;

library SignedDecimalMath {
    int256 constant ONE = 10**18;

    function decimalMul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        return (a * b) / ONE;
    }

    function decimalDiv(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        return (a * ONE) / b;
    }

    function abs(int256 a) internal pure returns (uint256) {
        return a < 0 ? uint256(a * -1) : uint256(a);
    }

}
