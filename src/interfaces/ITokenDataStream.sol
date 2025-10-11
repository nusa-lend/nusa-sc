// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenDataStream {
    function isStreaming(address _token) external view returns (bool);
    function tokenPriceFeed(address _token) external view returns (address);
    function setTokenStream(address _token, bool _status) external;
    function setTokenPriceFeed(address _token, address _priceFeed) external;
    function decimals(address _token) external view returns (uint256);
    function latestRoundData(address _token) external view returns (uint80, uint256, uint256, uint256, uint80);
}