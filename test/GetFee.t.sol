// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {GetFee} from "../src/devTools/GetFee.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";

contract GetFeeTest is Test, HelperDeployment {
    GetFee public getFee;

    address public alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        getFee = new GetFee(BASE_Router);
    }

    // RUN
    // forge test --match-contract GetFeeTest -vvvv
    function test_get_fee() public {
        vm.startPrank(alice);
        uint256 fee = getFee.getFee(alice, BASE_USDC, 42161, 100e6);

        console.log("fee", fee);
        vm.stopPrank();
    }
}
