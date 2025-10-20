// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Router} from "../src/Router.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Helper} from "../src/devtools/Helper.sol";
import {ILendingPool} from "../src/interfaces/ILendingPool.sol";

contract NusaUpgradeTest is Test, Helper, HelperDeployment {
    // ERC1967Proxy public proxy;
    LendingPool public lendingPool;
    LendingPool public lendingPoolProxy;
    address public owner = vm.envAddress("PUBLIC_KEY");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        lendingPoolProxy = LendingPool(payable(BASE_Proxy));
    }

    // RUN
    // forge test --match-contract NusaUpgradeTest --match-test test_upgrade -vvv
    function test_upgrade() public {
        vm.startPrank(owner);
        lendingPool = new LendingPool();
        console.log("totalBorrowAssets", lendingPoolProxy.totalBorrowAssets(BASE_USDC));
        console.log("borrowLtv", lendingPoolProxy.borrowLtv(BASE_USDC));
        // LendingPool(payable(BASE_Proxy)).upgradeToAndCall(address(lendingPool), "");
        lendingPoolProxy.upgradeToAndCall(address(lendingPool), "");
        console.log("totalBorrowAssets", lendingPoolProxy.totalBorrowAssets(BASE_USDC));
        console.log("borrowLtv", lendingPoolProxy.borrowLtv(BASE_USDC));

        ILendingPool(payable(BASE_Proxy)).borrow(owner, BASE_USDC, 1000e6, 8453);
        // proxy.upgradeToAndCall(address(lendingPool), "");
        vm.stopPrank();
    }
}
