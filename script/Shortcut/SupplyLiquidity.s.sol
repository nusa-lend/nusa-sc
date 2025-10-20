// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperDeployment} from "../../src/HelperDeployment.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILendingPool} from "../../src/interfaces/ILendingPool.sol";

contract SupplyLiquidityScript is Script, HelperDeployment {
    // *** FILL THIS ***
    address public user = vm.envAddress("PUBLIC_KEY");
    uint256 public amount = 10_000;
    // *****************

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    address public lendingPool;
    address public token;

    function run() public {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));

        lendingPool = block.chainid == 8453 ? BASE_Proxy : ARB_Proxy;
        token = block.chainid == 8453 ? BASE_USDC : ARB_USDC;

        vm.startBroadcast(privateKey);
        console.log("Token = %s", IERC20Metadata(token).name());
        console.log("Balance before SupplyLiquidity = %s", IERC20(token).balanceOf(user));

        IERC20(token).approve(lendingPool, amount * 10 ** IERC20Metadata(token).decimals());
        ILendingPool(lendingPool).supplyLiquidity(user, token, amount * 10 ** IERC20Metadata(token).decimals());

        console.log("Balance after SupplyLiquidity = %s", IERC20(token).balanceOf(user));
        vm.stopBroadcast();
    }
}

// RUN:
// forge script SupplyLiquidityScript --broadcast -vvv
// forge script SupplyLiquidityScript -vvv
