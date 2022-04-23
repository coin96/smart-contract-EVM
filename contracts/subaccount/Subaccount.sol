/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/
import "../intf/IDealer.sol";
import "../intf/ISubaccount.sol";

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

/// @notice Subaccount can help its owner manage risk and positions.
/// You can open orders with isolated positions via Subaccount.
/// You can also let others trade for you by setting them as authorized
/// operators. Operatiors have no access to fund transfer.
contract Subaccount is ISubaccount {
    // ========== storage ==========

    /*
       This is not a standard ownable contract because the ownership
       can not be transferred. This contract is designed to be
       initializable to better support clone, which is a low gas
       deployment solution.
    */
    address public owner;
    bool public initialized;

    // Operator white list. The operator can delegate trading when the value is true.
    mapping(address => bool) validOperator;

    // ========== modifier ==========

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // ========== functions ==========

    function init(address _owner) external {
        require(!initialized, "ALREADY INITIALIZED");
        initialized = true;
        owner = _owner;
    }

    /// @inheritdoc ISubaccount
    function isValidPerpetualOperator(address operator)
        external
        view
        returns (bool)
    {
        return operator == owner || validOperator[operator];
    }

    /// @param isValid authorize operator if value is true
    /// unauthorize operator if value is false
    function setOperator(address operator, bool isValid) external onlyOwner {
        validOperator[operator] = isValid;
    }

    /*
        Subaccount can only withdraw asset to its owner account.
        No deposit related function is supported in subaccount because the owner can
        transfer fund to subaccount directly in the Dealer contract. 
    */

    /// @param dealer As the subaccount can be used with more than one dealer,
    /// you need to pass this address in.
    /// @param primaryAmount The amount of primary asset you want to withdraw
    /// @param secondaryAmount The amount of secondary asset you want to withdraw
    function requestWithdraw(
        address dealer,
        uint256 primaryAmount,
        uint256 secondaryAmount
    ) external onlyOwner {
        IDealer(dealer).requestWithdraw(primaryAmount, secondaryAmount);
    }

    /// @notice Always withdraw to owner, no matter who fund this subaccount
    /// @param dealer As the subaccount can be used with more than one dealer,
    /// you need to pass this address in.
    function executeWithdraw(address dealer, bool isInternal) external onlyOwner {
        IDealer(dealer).executeWithdraw(owner, isInternal);
    }
}