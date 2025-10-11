// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingPool {
    function userCollateral(address _user, address _token) external view returns (uint256);
}