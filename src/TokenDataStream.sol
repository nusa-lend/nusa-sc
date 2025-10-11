// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "./interfaces/IOracle.sol";

contract TokenDataStream is Ownable {
    error TokenPriceFeedNotSet(address token);

    mapping(address => address) public tokenPriceFeed; // token => price feed

    event TokenPriceFeedSet(address token, address priceFeed);

    constructor() Ownable(msg.sender) {}

    function setTokenPriceFeed(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeed[_token] = _priceFeed;
        emit TokenPriceFeedSet(_token, _priceFeed);
    }

    function decimals(address _token) public view returns (uint256) {
        if (tokenPriceFeed[_token] == address(0)) revert TokenPriceFeedNotSet(_token);
        return IOracle(tokenPriceFeed[_token]).decimals();
    }

    function latestRoundData(address _token) public view returns (uint80, uint256, uint256, uint256, uint80) {
        if (tokenPriceFeed[_token] == address(0)) revert TokenPriceFeedNotSet(_token);
        (uint80 idRound, int256 priceAnswer, uint256 startedAt, uint256 updated, uint80 answeredInRound) =
            IOracle(tokenPriceFeed[_token]).latestRoundData();
        return (idRound, uint256(priceAnswer), startedAt, updated, answeredInRound);
    }
}
