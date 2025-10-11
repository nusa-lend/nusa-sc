// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IIsHealthy {
    function isHealthy(
        uint256 ltv,
        address user,
        address[] memory userCollateral,
        address borrowToken,
        uint256 totalBorrowAssets,
        uint256 totalBorrowShares,
        uint256 userBorrowShares
    ) external view;
}
