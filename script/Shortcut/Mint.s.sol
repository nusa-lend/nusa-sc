// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperDeployment} from "../../src/HelperDeployment.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken {
    function mint(address to, uint256 amount) external;
}

contract MintScript is Script, HelperDeployment {
    // *** FILL THIS ***
    address public token = BASE_bTSLA;
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    // address public minter = vm.envAddress("PUBLIC_KEY");
    address public minter = 0xfd1AF2826012385a84A8E9BE8a1586293FB3980B;
    uint256 public amount = 100_000_000;
    // *****************

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);
        console.log("Token = %s", IERC20Metadata(token).name());
        console.log("Balance before minting = %s", IERC20(token).balanceOf(minter));
        IToken(token).mint(minter, amount * 10 ** IERC20Metadata(token).decimals());
        console.log("Balance after minting = %s", IERC20(token).balanceOf(minter));
        vm.stopBroadcast();
    }
}

// RUN:
// forge script MintScript --broadcast -vvv
// forge script MintScript -vvv
