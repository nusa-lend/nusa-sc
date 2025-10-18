// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingPool {
    function totalBorrowAssets(address _token) external view returns (uint256);
    function totalBorrowShares(address _token) external view returns (uint256);
    function userCollateral(address _user, uint256 _chainId, address _token) external view returns (uint256);
    function tokenActive(address _token) external view returns (bool);
    function borrow(address _user, address _token, uint256 _amount, uint256 _chainDst) external;
    function repay(address _user, address _token, uint256 _shares) external;
    function supplyCollateral(address _user, address _token, uint256 _amount) external;
    function supplyLiquidity(address _user, address _token, uint256 _amount) external;
    function withdrawCollateral(address _user, address _token, uint256 _amount) external;
    function withdrawLiquidity(address _user, address _token, uint256 _amount) external;
}