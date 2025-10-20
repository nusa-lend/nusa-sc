// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Router is Ownable {
    address public tokenDataStream;
    address public isHealthy;
    address public lendingPool;

    mapping(uint256 => uint256) public chainIdToLzEid;
    mapping(uint256 => address) public chainIdToOApp;
    mapping(address => mapping(uint256 => address)) public crosschainTokenByChainId; // this chain token => dst chain id => token
    mapping(address => mapping(uint256 => address)) public crosschainTokenByLzEid; // this chain token => lz eid => token
    
    error LzEidNotSet(uint256 chainId, uint256 lzEid);

    event TokenDataStreamSet(address tokenDataStream);
    event IsHealthySet(address isHealthy);
    event LendingPoolSet(address lendingPool);
    event ChainIdToLzEidSet(uint256 chainId, uint256 lzEid);
    event ChainIdToOAppSet(uint256 chainId, address oApp);
    event CrosschainTokenSet(address token, uint256 chainDst, uint256 lzEid, address crosschainToken);

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

    function setChainIdToLzEid(uint256 _chainId, uint256 _lzEid) public onlyOwner {
        chainIdToLzEid[_chainId] = _lzEid;
        emit ChainIdToLzEidSet(_chainId, _lzEid);
    }

    function setChainIdToOApp(uint256 _chainId, address _oApp) public onlyOwner {
        chainIdToOApp[_chainId] = _oApp;
        emit ChainIdToOAppSet(_chainId, _oApp);
    }

    function setCrosschainToken(address _token, uint256 _chainDst, address _crosschainToken) public onlyOwner {
        uint256 _lzEid = chainIdToLzEid[_chainDst];
        if (_lzEid == 0) revert LzEidNotSet(_chainDst, _lzEid);
        crosschainTokenByLzEid[_token][_lzEid] = _crosschainToken;
        crosschainTokenByChainId[_token][_chainDst] = _crosschainToken;
        emit CrosschainTokenSet(_token, _chainDst, _lzEid, _crosschainToken);
    }
}
