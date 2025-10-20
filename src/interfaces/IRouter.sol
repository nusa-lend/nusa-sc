// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function chainIdToOApp(uint256 _chainId) external view returns (address);
    function chainIdToLzEid(uint256 _chainId) external view returns (uint256);
    function crosschainTokenByChainId(address _token, uint256 _chainDst) external view returns (address);
    function crosschainTokenByLzEid(address _token, uint256 _lzEid) external view returns (address);
    function tokenDataStream() external view returns (address);
    function lendingPool() external view returns (address);
    function isHealthy() external view returns (address);
}