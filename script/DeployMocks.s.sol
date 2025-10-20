// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {CADC} from "../src/mocks/CADC.sol";
import {CNGN} from "../src/mocks/CNGN.sol";
import {KRWT} from "../src/mocks/KRWT.sol";
import {TRYB} from "../src/mocks/TRYB.sol";
import {MXNE} from "../src/mocks/MXNE.sol";
import {XSGD} from "../src/mocks/XSGD.sol";
import {ZARP} from "../src/mocks/ZARP.sol";
import {IDRX} from "../src/mocks/IDRX.sol";
import {EURC} from "../src/mocks/EURC.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {WBTC} from "../src/mocks/WBTC.sol";

contract DeployMocks is Script {
    // Token instances
    CADC public cadc;
    CNGN public cngn;
    KRWT public krwt;
    TRYB public tryb;
    MXNE public mxne;
    XSGD public xsgd;
    ZARP public zarp;
    IDRX public idrx;
    EURC public eurc;
    USDC public usdc;
    WETH public weth;
    WBTC public wbtc;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(privateKey);

    function run() external {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));

        console.log("Deploying all mock tokens with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(privateKey);

        _deployAllTokens();

        vm.stopBroadcast();
    }

    function _deployAllTokens() internal {
        // Deploy CADC (18 decimals)
        cadc = new CADC();
        _logTokenAddress("CADC", address(cadc));

        // Deploy CNGN (6 decimals)
        cngn = new CNGN();
        _logTokenAddress("CNGN", address(cngn));

        // Deploy KRWT (18 decimals)
        krwt = new KRWT();
        _logTokenAddress("KRWT", address(krwt));

        // Deploy TRYB (6 decimals)
        tryb = new TRYB();
        _logTokenAddress("TRYB", address(tryb));

        // Deploy MXNE (6 decimals)
        mxne = new MXNE();
        _logTokenAddress("MXNE", address(mxne));

        // Deploy XSGD (6 decimals)
        xsgd = new XSGD();
        _logTokenAddress("XSGD", address(xsgd));

        // Deploy ZARP (18 decimals)
        zarp = new ZARP();
        _logTokenAddress("ZARP", address(zarp));

        // Deploy IDRX (2 decimals)
        idrx = new IDRX();
        _logTokenAddress("IDRX", address(idrx));

        // Deploy EURC (6 decimals)
        eurc = new EURC();
        _logTokenAddress("EURC", address(eurc));

        // Deploy USDC (6 decimals)
        usdc = new USDC();
        _logTokenAddress("USDC", address(usdc));

        // Deploy WETH (18 decimals)
        weth = new WETH();
        _logTokenAddress("WETH", address(weth));

        // Deploy WBTC (8 decimals)
        wbtc = new WBTC();
        _logTokenAddress("WBTC", address(wbtc));

        console.log("\n=== All mock tokens deployed successfully ===");
        console.log("Total tokens deployed: 12");
    }

    function _logTokenAddress(string memory tokenName, address tokenAddress) internal view {
        string memory prefix = block.chainid == 8453 ? "BASE" : "ARB";
        console.log("address public %s_%s = %s;", prefix, tokenName, tokenAddress);
    }
}

// RUN COMMANDS:
// forge script DeployMocks --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployMocks --broadcast -vvv
// forge script DeployMocks -vvv
