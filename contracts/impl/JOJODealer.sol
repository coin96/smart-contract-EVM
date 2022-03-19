/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./JOJOView.sol";
import "./JOJOExternal.sol";
import "./JOJOOperation.sol";
import "../lib/EIP712.sol";

contract JOJODealer is JOJOView, JOJOExternal, JOJOOperation {
    constructor(address _underlyingAsset) Ownable() {
        state.underlyingAsset = _underlyingAsset;
        state.domainSeparator = EIP712._buildDomainSeparator(
            "JOJO",
            "1",
            address(this)
        );
    }
}
