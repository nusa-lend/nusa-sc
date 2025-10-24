// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "./interfaces/IOracle.sol";

/**
 * @title TokenDataStream
 * @author Nusa Protocol Team
 * @notice Contract that manages price feed mappings for tokens in the lending protocol
 * @dev This contract acts as a registry that maps token addresses to their corresponding
 *      price feed contracts. It provides a unified interface for accessing token price data
 *      from various oracle sources while maintaining Chainlink compatibility.
 * 
 * Key Features:
 * - Token to price feed address mapping
 * - Chainlink-compatible price data interface
 * - Owner-controlled price feed configuration
 * - Decimal precision handling for different oracles
 * - Centralized price data access point for the protocol
 */
contract TokenDataStream is Ownable {
    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when attempting to access price data for a token without a configured price feed
    /// @param token The token address that doesn't have a price feed configured
    error TokenPriceFeedNotSet(address token);

    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Mapping of token addresses to their corresponding price feed contract addresses
    /// @dev token address => price feed contract address
    mapping(address => address) public tokenPriceFeed;

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when a token's price feed is configured or updated
    /// @param token The token address that was configured
    /// @param priceFeed The price feed contract address that was set
    event TokenPriceFeedSet(address token, address priceFeed);

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the TokenDataStream contract
    /// @dev Sets up Ownable with the deployer as the initial owner
    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                   CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Sets or updates the price feed contract for a token
    /// @dev Only the contract owner can call this function
    /// @param _token The token address to configure
    /// @param _priceFeed The price feed contract address for this token
    function setTokenPriceFeed(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeed[_token] = _priceFeed;
        emit TokenPriceFeedSet(_token, _priceFeed);
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /// @notice Returns the number of decimals used by a token's price feed
    /// @dev Calls the decimals function on the configured price feed contract
    /// @param _token The token address to get decimals for
    /// @return The number of decimals used by the token's price feed
    function decimals(address _token) public view returns (uint256) {
        if (tokenPriceFeed[_token] == address(0)) revert TokenPriceFeedNotSet(_token);
        return IOracle(tokenPriceFeed[_token]).decimals();
    }

    /// @notice Returns the latest price data for a token in Chainlink-compatible format
    /// @dev Retrieves price data from the configured price feed and converts int256 price to uint256
    /// @param _token The token address to get price data for
    /// @return roundId The round ID from the price feed
    /// @return price The price value (converted from int256 to uint256)
    /// @return startedAt Timestamp when the round started
    /// @return updatedAt Timestamp when the price was last updated
    /// @return answeredInRound The round when this answer was computed
    function latestRoundData(address _token) public view returns (uint80, uint256, uint256, uint256, uint80) {
        if (tokenPriceFeed[_token] == address(0)) revert TokenPriceFeedNotSet(_token);
        (uint80 idRound, int256 priceAnswer, uint256 startedAt, uint256 updated, uint80 answeredInRound) =
            IOracle(tokenPriceFeed[_token]).latestRoundData();
        return (idRound, uint256(priceAnswer), startedAt, updated, answeredInRound);
    }
}
