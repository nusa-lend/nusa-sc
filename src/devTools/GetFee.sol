// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouter} from "../interfaces/IRouter.sol";
import {IOAppBorrow} from "../interfaces/IOAppBorrow.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title GetFee
 * @author Nusa Protocol Team
 * @notice Contract that gets the fee for a given destination chain ID
 * @dev This contract is used to get the fee for a given destination chain ID
 */
contract GetFee {
    address public router;

    constructor(address _router) {
        router = _router;
    }

    function getFee(address _sender, address _token, uint256 _chainIdDst, uint256 _amount)
        public
        view
        returns (uint256)
    {
        address token =
            IRouter(router).crosschainTokenByLzEid(_token, uint32(IRouter(router).chainIdToLzEid(_chainIdDst)));
        MessagingFee memory fee = IOAppBorrow(IRouter(router).chainIdToOApp(block.chainid)).quoteSendString(
            uint32(IRouter(router).chainIdToLzEid(_chainIdDst)), _amount, token, _sender, "", false
        );
        return fee.nativeFee;
    }

    function setFactory(address _router) public {
        router = _router;
    }
}
