// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingPool {
    function userCollateral(address _user, address _token) external view returns (uint256);
    function tokenActive(address _token) external view returns (bool);
    function borrow(address _user, address _token, uint256 _amount, uint256 _chainDst) external;
}