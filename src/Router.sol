// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Router is Ownable {
    address public tokenDataStream;
    address public isHealthy;
    address public lendingPool;

    event TokenDataStreamSet(address tokenDataStream);
    event IsHealthySet(address isHealthy);
    event LendingPoolSet(address lendingPool);

    constructor() Ownable(msg.sender) {}

    function setTokenDataStream(address _tokenDataStream) public onlyOwner {
        tokenDataStream = _tokenDataStream;
        emit TokenDataStreamSet(_tokenDataStream);
    }

    function setIsHealthy(address _isHealthy) public onlyOwner {
        isHealthy = _isHealthy;
        emit IsHealthySet(_isHealthy);
    }

    function setLendingPool(address _lendingPool) public onlyOwner {
        lendingPool = _lendingPool;
        emit LendingPoolSet(_lendingPool);
    }
}
