// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

interface IOAppBorrow {
    // Core functions
    function sendString(uint32 _dstEid, uint256 _amount, address _token, bytes calldata _options) external payable;
    function quoteSendString(
        uint32 _dstEid,
        uint256 _amount,
        address _token,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee);
    
    // Configuration functions
    function setLendingPool(address _lendingPool) external;
    function setRouter(address _router) external;
    
    // View functions
    function lendingPool() external view returns (address);
    function router() external view returns (address);
    function lastMessage() external view returns (bytes memory);
    
    // Events
    event MessageReceived(uint32 indexed srcEid, address indexed sender, uint64 nonce, address token);
    event SetLendingPool(address lendingPool);
}