// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {GetFee} from "../src/devTools/GetFee.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";

contract DeployGetFee is Script, HelperDeployment {
    GetFee public getFee;
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(privateKey);
        _deployGetFee();
        console.log("address public BASE_GetFee:", address(getFee));
        vm.stopBroadcast();
    }

    function _deployGetFee() internal {
        getFee = new GetFee(BASE_Router);
    }
}

// RUN
// forge script DeployGetFee --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployGetFee --broadcast -vvv
// forge script DeployGetFee -vvv
