// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Router} from "../src/Router.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {ILendingPool} from "../src/interfaces/ILendingPool.sol";

contract DeployRouterScript is Script, HelperDeployment {
    uint256 public privateKey = vm.envUint("PRIVATE_KEY");
    address public deployer = vm.addr(privateKey);

    Router public router;

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);
        // Router router = new Router();
        router = Router(block.chainid == 8453 ? BASE_Router : ARB_Router);
        block.chainid == 8453
            ? console.log("address public BASE_Router = %s;", address(router))
            : console.log("address public ARB_Router = %s;", address(router));
        router.setTokenDataStream(block.chainid == 8453 ? BASE_TokenDataStream : ARB_TokenDataStream);
        router.setIsHealthy(block.chainid == 8453 ? BASE_IsHealthy : ARB_IsHealthy);
        router.setLendingPool(block.chainid == 8453 ? BASE_Proxy : ARB_Proxy);
        router.setChainIdToLzEid(block.chainid == 8453 ? 8453 : 42161, BASE_EID);
        router.setChainIdToLzEid(block.chainid == 8453 ? 42161 : 8453, ARB_EID);
        router.setChainIdToOApp(
            block.chainid == 8453 ? 8453 : 42161, block.chainid == 8453 ? BASE_OAppBorrow : ARB_OAppBorrow
        );
        router.setCrosschainToken(
            block.chainid == 8453 ? BASE_USDC : ARB_USDC,
            block.chainid == 8453 ? 42161 : 8453,
            block.chainid == 8453 ? ARB_USDC : BASE_USDC
        );
        router.setCrosschainToken(
            block.chainid == 8453 ? BASE_WETH : ARB_WETH,
            block.chainid == 8453 ? 42161 : 8453,
            block.chainid == 8453 ? ARB_WETH : BASE_WETH
        );

        ILendingPool(block.chainid == 8453 ? BASE_Proxy : ARB_Proxy).setRouter(address(router));
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployRouterScript -vvv --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployRouterScript -vvv --broadcast
// forge script DeployRouterScript -vvv
