/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
    ONLY FOR TEST
    DO NOT DEPLOY IN PRODUCTION ENV
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/internal/IPriceSource.sol";


contract MockSwap {

    using SafeERC20 for IERC20;
    address USDC;
    address wstETH;
    mapping(address => address) tokenPrice;

    constructor(address _USDC, address _wstETH, address _price) {
        USDC = _USDC;
        wstETH = _wstETH;
        tokenPrice[_wstETH] = _price;
    }

    function addTokenPrice(address token, address price) public {
        tokenPrice[token] = price;
    }

    function swapToWstETH(uint256 amount, address token) external {
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
        uint256 value = amount * 1e18 /
            IPriceSource(tokenPrice[token]).getAssetPrice();
        IERC20(wstETH).safeTransfer(msg.sender, value);
    }

    function swapToUSDC(uint256 amount, address token) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 value = amount * IPriceSource(tokenPrice[token]).getAssetPrice() / 1e18;
        IERC20(USDC).safeTransfer(msg.sender, value);
    }

    function getSwapToWstETHData(
        uint256 amount,
        address token
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("swapToWstETH(uint256,address)", amount, token);
    }

    function getSwapToUSDCData(
        uint256 amount,
        address token
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature("swapToUSDC(uint256,address)", amount, token);
    }
}
