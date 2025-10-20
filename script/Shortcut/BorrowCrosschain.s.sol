// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Router} from "../../src/Router.sol";
import {HelperDeployment} from "../../src/HelperDeployment.sol";
import {ILendingPool} from "../../src/interfaces/ILendingPool.sol";
import {IOAppBorrow} from "../../src/interfaces/IOAppBorrow.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract BorrowCrosschainScript is Script, HelperDeployment {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address public user = vm.envAddress("PUBLIC_KEY");

    address public lendingPool;
    address public token;
    address public router;

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);
        uint256 amount = 500e6;

        lendingPool = block.chainid == 8453 ? BASE_Proxy : ARB_Proxy;
        token = block.chainid == 8453 ? BASE_USDC : ARB_USDC;
        router = block.chainid == 8453 ? BASE_Router : ARB_Router;

        address crosschainToken = Router(router).crosschainTokenByChainId(address(token), block.chainid == 8453 ? 42161 : 8453);
        MessagingFee memory fee = IOAppBorrow(Router(router).chainIdToOApp(block.chainid)).quoteSendString(
            uint32(Router(router).chainIdToLzEid(block.chainid == 8453 ? 42161 : 8453)),
            amount,
            address(crosschainToken),
            "",
            false
        );
        console.log("fee", fee.nativeFee);

        ILendingPool(lendingPool).borrow{value: fee.nativeFee}(
            user, token, amount, block.chainid == 8453 ? 42161 : 8453
        );
        vm.stopBroadcast();
    }
}

// RUN
// forge script BorrowCrosschainScript --broadcast -vvv
// forge script BorrowCrosschainScript -vvv
// forge script BorrowCrosschainScript --broadcast
// forge script BorrowCrosschainScript