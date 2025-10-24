// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title IOAppBorrow
 * @author Nusa Protocol Team
 * @notice Interface for the OAppBorrow contract that handles cross-chain borrowing via LayerZero
 * @dev This interface defines functions for sending borrow requests across chains and managing
 *      LayerZero OApp functionality for the lending protocol
 */
interface IOAppBorrow {
    // =============================================================
    //                        CORE FUNCTIONS
    // =============================================================

    /// @notice Sends a cross-chain borrow message via LayerZero
    /// @param _dstEid The LayerZero endpoint ID of the destination chain
    /// @param _amount The amount of tokens to borrow
    /// @param _token The token address to borrow
    /// @param _user The user address that will receive the borrowed tokens
    /// @param _options LayerZero message options for gas and execution parameters
    function sendString(uint32 _dstEid, uint256 _amount, address _token, address _user, bytes calldata _options)
        external
        payable;

    /// @notice Quotes the fee for sending a cross-chain borrow message
    /// @param _dstEid The LayerZero endpoint ID of the destination chain
    /// @param _amount The amount of tokens to borrow
    /// @param _token The token address to borrow
    /// @param _user The user address that will receive the borrowed tokens
    /// @param _options LayerZero message options for gas and execution parameters
    /// @param _payInLzToken Whether to pay fees in LayerZero token
    /// @return fee The messaging fee structure containing native and LZ token costs
    function quoteSendString(
        uint32 _dstEid,
        uint256 _amount,
        address _token,
        address _user,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee);

    // =============================================================
    //                   CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Sets the lending pool contract address
    /// @param _lendingPool The lending pool contract address
    function setLendingPool(address _lendingPool) external;

    /// @notice Sets the router contract address
    /// @param _router The router contract address
    function setRouter(address _router) external;

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /// @notice Returns the lending pool contract address
    /// @return The lending pool contract address
    function lendingPool() external view returns (address);

    /// @notice Returns the router contract address
    /// @return The router contract address
    function router() external view returns (address);

    /// @notice Returns the last received cross-chain message
    /// @return The last message data as bytes
    function lastMessage() external view returns (bytes memory);

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when a cross-chain message is received
    /// @param srcEid The source LayerZero endpoint ID
    /// @param sender The sender address (user receiving borrowed tokens)
    /// @param nonce The LayerZero message nonce
    /// @param token The token address being borrowed
    event MessageReceived(uint32 indexed srcEid, address indexed sender, uint64 nonce, address token);

    /// @notice Emitted when the lending pool address is updated
    /// @param lendingPool The new lending pool address
    event SetLendingPool(address lendingPool);
}
