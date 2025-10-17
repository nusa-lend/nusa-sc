// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

interface IOAppBorrow {
    function sendString(uint32 _dstEid, uint256 _amount, address _token, bytes calldata _options) external payable;
    function quoteSendString(
        uint32 _dstEid,
        uint256 _amount,
        address _token,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee);
}