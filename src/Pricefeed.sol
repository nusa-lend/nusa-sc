// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Pricefeed is Ownable {
    error PricefeedNotSet(address token);

    uint8 public decimals = 8;
    uint80 public idRound;
    int256 public priceAnswer;
    uint256 public startedAt;
    uint256 public updated;
    uint80 public answeredInRound;
    address public token;

    event PriceSet(uint80 idRound, int256 priceAnswer, uint256 startedAt, uint256 updated, uint80 answeredInRound);
    event TokenSet(address token);

    constructor(address _token) Ownable(msg.sender) {
        setToken(_token);
    }

    function setPrice(
        uint80 _idRound,
        int256 _priceAnswer,
        uint256 _startedAt,
        uint256 _updated,
        uint80 _answeredInRound
    ) public onlyOwner {
        idRound = _idRound;
        priceAnswer = _priceAnswer;
        startedAt = _startedAt;
        updated = _updated;
        answeredInRound = _answeredInRound;

        emit PriceSet(_idRound, _priceAnswer, _startedAt, _updated, _answeredInRound);
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
        emit TokenSet(_token);
    }

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (idRound, priceAnswer, startedAt, updated, answeredInRound);
    }
}
