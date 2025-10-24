// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IIsHealthy
 * @author Nusa Protocol Team
 * @notice Interface for the IsHealthy contract that validates borrowing position health
 * @dev This interface defines the function for checking if a user's borrowing position
 *      remains healthy based on their collateral and debt ratios
 */
interface IIsHealthy {
    /// @notice Validates whether a user's borrowing position is healthy
    /// @dev This function should revert if the position is unhealthy (under-collateralized)
    /// @param ltv The loan-to-value ratio for the borrowed token
    /// @param user The user address whose position is being checked
    /// @param userCollateral Array of collateral token addresses the user has deposited
    /// @param borrowToken The token address being borrowed
    /// @param totalBorrowAssets Total amount of assets borrowed for this token
    /// @param totalBorrowShares Total borrow shares issued for this token
    /// @param userBorrowShares The user's borrow shares for this token
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
