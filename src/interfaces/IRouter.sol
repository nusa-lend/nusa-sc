// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function tokenDataStream() external view returns (address);
    function lendingPool() external view returns (address);
    function isHealthy() external view returns (address);
}