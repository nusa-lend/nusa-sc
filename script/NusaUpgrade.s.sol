// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract NusaUpgradeScript is Script, HelperDeployment {
    LendingPool public lendingPool;

    function run() public {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        lendingPool = new LendingPool();
        LendingPool(payable(block.chainid == 8453 ? BASE_Proxy : ARB_Proxy)).upgradeToAndCall(address(lendingPool), "");
        block.chainid == 8453
            ? console.log("address public BASE_LendingPool", address(lendingPool))
            : console.log("address public ARB_LendingPool", address(lendingPool));
        vm.stopBroadcast();
    }
}

// RUN
// forge script NusaUpgradeScript --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script NusaUpgradeScript --broadcast
// forge script NusaUpgradeScript -vvv
// forge script NusaUpgradeScript
