// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {ITokenDataStream} from "./interfaces/ITokenDataStream.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title IsHealthy
 * @author Nusa Protocol Team
 * @notice Contract that validates the health of borrowing positions based on collateral ratios
 * @dev This contract implements health checks for lending positions by comparing the value
 *      of a user's collateral against their borrowed amount and the loan-to-value (LTV) ratio.
 *      It prevents users from borrowing more than their collateral can safely support.
 * 
 * Key Features:
 * - Multi-token collateral support across different chains
 * - Real-time price feed integration via TokenDataStream
 * - Configurable loan-to-value ratios per token
 * - Automatic liquidation threshold detection
 * - Precision handling for different token decimals
 */
contract IsHealthy is Ownable {
    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when a borrowing position becomes unhealthy (insufficient collateral)
    /// @param borrowValue The USD value of the borrowed amount
    /// @param collateralValue The USD value of the user's collateral
    /// @param maxBorrow The maximum USD amount that can be borrowed based on LTV
    error InsufficientCollateral(uint256 borrowValue, uint256 collateralValue, uint256 maxBorrow);

    /// @notice Thrown when an invalid loan-to-value ratio is provided (e.g., zero)
    /// @param ltv The invalid LTV ratio that was provided
    error InvalidLtv(uint256 ltv);

    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Address of the Router contract for accessing protocol configurations
    address public router;

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the IsHealthy contract with a router address
    /// @dev Sets up Ownable with deployer as owner and configures the router
    /// @param _router The router contract address for accessing protocol configurations
    constructor(address _router) Ownable(msg.sender) {
        router = _router;
    }

    // =============================================================
    //                   CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Updates the router contract address
    /// @dev Only the contract owner can call this function
    /// @param _router The new router contract address
    function setRouter(address _router) public onlyOwner {
        router = _router;
    }

    // =============================================================
    //                        HEALTH CHECK FUNCTIONS
    // =============================================================

    /// @notice Validates whether a user's borrowing position is healthy
    /// @dev Calculates the total USD value of user's collateral across all supported tokens
    ///      and compares it against their borrowed amount and the LTV threshold.
    ///      Reverts if the position is unhealthy (over-leveraged).
    /// @param ltv The loan-to-value ratio for the borrowed token (with 18 decimal precision)
    /// @param user The user address whose position is being checked
    /// @param borrowToken The token address being borrowed
    /// @param tokens Array of collateral token addresses to check
    /// @param chainIds Array of chain IDs (currently unused but kept for interface compatibility)
    /// @param totalBorrowAssets Total amount of assets borrowed for this token across all users
    /// @param totalBorrowShares Total borrow shares issued for this token
    /// @param userBorrowShares The user's borrow shares for this token
    /// @param lendingPool The lending pool contract address
    function isHealthy(
        uint256 ltv,
        address user,
        address borrowToken,
        address[] memory tokens,
        uint256[] memory chainIds,
        uint256 totalBorrowAssets,
        uint256 totalBorrowShares,
        uint256 userBorrowShares,
        address lendingPool
    ) public view {
        if (ltv == 0) revert InvalidLtv(ltv);
        
        // If user has no borrows, they're always healthy
        if (userBorrowShares == 0 || totalBorrowShares == 0) {
            return;
        }
        
        (, uint256 borrowPrice,,,) = ITokenDataStream(IRouter(router).tokenDataStream()).latestRoundData(borrowToken);
        uint256 collateralValue = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token != address(0) && ILendingPool(lendingPool).tokenActive(token)) {
                uint256 userCollateralAmount = _userCollateralAmount(user, tokens[i]);
                uint256 collateralAdjustedPrice =
                    _userCollateralPrice(tokens[i]) * 1e18 / 10 ** _oracleDecimal(tokens[i]);
                uint256 userCollateralValue =
                    userCollateralAmount * collateralAdjustedPrice / (10 ** _tokenDecimals(tokens[i]));
                collateralValue += userCollateralValue;
            }
        }
        uint256 borrowed = (userBorrowShares * totalBorrowAssets) / totalBorrowShares;
        uint256 borrowAdjustedPrice = uint256(borrowPrice) * 1e18 / 10 ** _oracleDecimal(borrowToken);
        uint256 borrowValue = (borrowed * borrowAdjustedPrice) / (10 ** _tokenDecimals(borrowToken));

        uint256 maxBorrow = (collateralValue * ltv) / 1e18;

        bool isLiquidatable = (borrowValue > collateralValue) || (borrowValue > maxBorrow);

        if (isLiquidatable) {
            revert InsufficientCollateral(borrowValue, collateralValue, maxBorrow);
        }
    }

    // =============================================================
    //                    INTERNAL HELPER FUNCTIONS
    // =============================================================

    /// @notice Gets the amount of collateral a user has deposited for a specific token
    /// @dev Queries the lending pool for the user's collateral balance on the current chain
    /// @param _user The user address to query
    /// @param _token The collateral token address
    /// @return The amount of collateral the user has deposited
    function _userCollateralAmount(address _user, address _token) internal view returns (uint256) {
        return ILendingPool(IRouter(router).lendingPool()).userCollateral(_user, block.chainid, _token);
    }

    /// @notice Gets the current price of a collateral token from the price feed
    /// @dev Retrieves the latest price data from the TokenDataStream oracle
    /// @param _token The token address to get the price for
    /// @return The current price of the token from the oracle
    function _userCollateralPrice(address _token) internal view returns (uint256) {
        (, uint256 price,,,) = ITokenDataStream(IRouter(router).tokenDataStream()).latestRoundData(_token);
        return price;
    }

    /// @notice Gets the number of decimals used by the oracle for a token's price
    /// @dev Used to properly normalize price values from different oracle sources
    /// @param _token The token address to get oracle decimals for
    /// @return The number of decimals used by the token's price oracle
    function _oracleDecimal(address _token) internal view returns (uint256) {
        return ITokenDataStream(IRouter(router).tokenDataStream()).decimals(_token);
    }

    /// @notice Gets the number of decimals used by an ERC20 token
    /// @dev Used to properly normalize token amounts for value calculations
    /// @param _token The token address to get decimals for
    /// @return The number of decimals used by the ERC20 token
    function _tokenDecimals(address _token) internal view returns (uint256) {
        return IERC20Metadata(_token).decimals();
    }
}
