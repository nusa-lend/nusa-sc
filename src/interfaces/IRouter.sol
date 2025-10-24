// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRouter
 * @author Nusa Protocol Team
 * @notice Interface for the Router contract that manages cross-chain configurations
 * @dev This interface defines functions for accessing cross-chain mappings and protocol contract addresses
 */
interface IRouter {
    /// @notice Returns the OApp contract address for a given chain ID
    /// @param _chainId The chain ID to query
    /// @return The OApp contract address for the specified chain
    function chainIdToOApp(uint256 _chainId) external view returns (address);

    /// @notice Returns the LayerZero endpoint ID for a given chain ID
    /// @param _chainId The chain ID to query
    /// @return The LayerZero endpoint ID for the specified chain
    function chainIdToLzEid(uint256 _chainId) external view returns (uint256);

    /// @notice Returns the corresponding token address on another chain by chain ID
    /// @param _token The local token address
    /// @param _chainDst The destination chain ID
    /// @return The corresponding token address on the destination chain
    function crosschainTokenByChainId(address _token, uint256 _chainDst) external view returns (address);

    /// @notice Returns the corresponding token address on another chain by LayerZero endpoint ID
    /// @param _token The local token address
    /// @param _lzEid The LayerZero endpoint ID
    /// @return The corresponding token address on the destination chain
    function crosschainTokenByLzEid(address _token, uint256 _lzEid) external view returns (address);

    /// @notice Returns the TokenDataStream contract address
    /// @return The TokenDataStream contract address
    function tokenDataStream() external view returns (address);

    /// @notice Returns the LendingPool contract address
    /// @return The LendingPool contract address
    function lendingPool() external view returns (address);

    /// @notice Returns the IsHealthy contract address
    /// @return The IsHealthy contract address
    function isHealthy() external view returns (address);
}