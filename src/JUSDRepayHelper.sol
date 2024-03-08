/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IJUSDExchange.sol";
import "./JUSDBank.sol";

pragma solidity ^0.8.19;

contract JUSDRepayHelper is Ownable {
    using SafeERC20 for IERC20;
    using SignedDecimalMath for uint256;

    JUSDBank public immutable JusdBank;
    address public immutable JUSD;
    address public immutable USDC;
    address public immutable JUSDExchange;
    uint256 public buffer;

    mapping(address => bool) public adminWhiteList;

    event UpdateAdmin(address admin, bool isValid);
    event HelpToTransfer(address from, address to, uint256 amount);

    constructor(address _jusdBank, address _JUSD, address _USDC, address _JUSDExchange) Ownable() {
        // set params
        JusdBank = JUSDBank(_jusdBank);
        JUSD = _JUSD;
        USDC = _USDC;
        JUSDExchange = _JUSDExchange;
        IERC20(JUSD).approve(address(JusdBank), type(uint256).max);
    }

    modifier onlyAdminWhiteList() {
        require(adminWhiteList[msg.sender], "caller is not in the admin white list");
        _;
    }

    function setWhiteList(address admin, bool isValid) public onlyOwner {
        adminWhiteList[admin] = isValid;
        emit UpdateAdmin(admin, isValid);
    }

    function setBuffer(uint256 newBuffer) public onlyOwner {
        buffer = newBuffer;
    }

    /// @notice This is to facilitate the withdrawal of USDC/JUSD from the trading account,
    /// and repay the withdrawal USDC/JUSD directly to the lending platform without any other steps.
    /// check the test `testJOJOSubaccountRepayFromPerp`
    /// @param from The from account.
    /// @param to is the address received assets.
    function repayToBank(address from, address to) external onlyAdminWhiteList {
        uint256 USDCBalance = IERC20(USDC).balanceOf(address(this));
        if (USDCBalance > 0) {
            IERC20(USDC).approve(JUSDExchange, USDCBalance);
            IJUSDExchange(JUSDExchange).buyJUSD(USDCBalance, address(this));
        }
        uint256 balance = IERC20(JUSD).balanceOf(address(this));
        uint256 borrowed = IJUSDBank(JusdBank).getBorrowBalance(to);
        // add buffer JUSD
        require(balance <= borrowed + buffer, "repayed jusd too much");
        IJUSDBank(JusdBank).repay(balance, to);
        IERC20(JUSD).safeTransfer(JusdBank.insurance(), balance - borrowed);
        emit HelpToTransfer(from, to, balance);
    }
}
