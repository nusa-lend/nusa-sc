// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Pricefeed} from "../src/Pricefeed.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";

contract DeployPricefeeds is Script, HelperDeployment {
    // Pricefeed instances
    Pricefeed public cadcPricefeed;
    Pricefeed public cngnPricefeed;
    Pricefeed public krwtPricefeed;
    Pricefeed public trybPricefeed;
    Pricefeed public mxnePricefeed;
    Pricefeed public xsgdPricefeed;
    Pricefeed public zarpPricefeed;
    Pricefeed public idrxPricefeed;
    Pricefeed public eurcPricefeed;
    Pricefeed public usdcPricefeed;
    Pricefeed public wethPricefeed;
    Pricefeed public wbtcPricefeed;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(privateKey);

    function run() external {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));

        console.log("Deploying all pricefeeds with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(privateKey);

        _deployAllPricefeeds();
        _setInitialPrices();

        vm.stopBroadcast();
    }

    function _deployAllPricefeeds() internal {
        // Get token addresses from HelperDeployment
        address cadcToken = block.chainid == 8453 ? BASE_CADC : ARB_CADC;
        address cngnToken = block.chainid == 8453 ? BASE_CNGN : ARB_CNGN;
        address krwtToken = block.chainid == 8453 ? BASE_KRWT : ARB_KRWT;
        address trybToken = block.chainid == 8453 ? BASE_TRYB : ARB_TRYB;
        address mxneToken = block.chainid == 8453 ? BASE_MXNE : ARB_MXNE;
        address xsgdToken = block.chainid == 8453 ? BASE_XSGD : ARB_XSGD;
        address zarpToken = block.chainid == 8453 ? BASE_ZARP : ARB_ZARP;
        address idrxToken = block.chainid == 8453 ? BASE_IDRX : ARB_IDRX;
        address eurcToken = block.chainid == 8453 ? BASE_EURC : ARB_EURC;
        address usdcToken = block.chainid == 8453 ? BASE_USDC : ARB_USDC;
        address wethToken = block.chainid == 8453 ? BASE_WETH : ARB_WETH;
        address wbtcToken = block.chainid == 8453 ? BASE_WBTC : ARB_WBTC;

        // Deploy CADC Pricefeed
        cadcPricefeed = new Pricefeed(cadcToken);
        _logPricefeedAddress("CADC_Pricefeed", address(cadcPricefeed));

        // Deploy CNGN Pricefeed
        cngnPricefeed = new Pricefeed(cngnToken);
        _logPricefeedAddress("CNGN_Pricefeed", address(cngnPricefeed));

        // Deploy KRWT Pricefeed
        krwtPricefeed = new Pricefeed(krwtToken);
        _logPricefeedAddress("KRWT_Pricefeed", address(krwtPricefeed));

        // Deploy TRYB Pricefeed
        trybPricefeed = new Pricefeed(trybToken);
        _logPricefeedAddress("TRYB_Pricefeed", address(trybPricefeed));

        // Deploy MXNE Pricefeed
        mxnePricefeed = new Pricefeed(mxneToken);
        _logPricefeedAddress("MXNE_Pricefeed", address(mxnePricefeed));

        // Deploy XSGD Pricefeed
        xsgdPricefeed = new Pricefeed(xsgdToken);
        _logPricefeedAddress("XSGD_Pricefeed", address(xsgdPricefeed));

        // Deploy ZARP Pricefeed
        zarpPricefeed = new Pricefeed(zarpToken);
        _logPricefeedAddress("ZARP_Pricefeed", address(zarpPricefeed));

        // Deploy IDRX Pricefeed
        idrxPricefeed = new Pricefeed(idrxToken);
        _logPricefeedAddress("IDRX_Pricefeed", address(idrxPricefeed));

        // Deploy EURC Pricefeed
        eurcPricefeed = new Pricefeed(eurcToken);
        _logPricefeedAddress("EURC_Pricefeed", address(eurcPricefeed));

        // Deploy USDC Pricefeed
        usdcPricefeed = new Pricefeed(usdcToken);
        _logPricefeedAddress("USDC_Pricefeed", address(usdcPricefeed));

        // Deploy WETH Pricefeed
        wethPricefeed = new Pricefeed(wethToken);
        _logPricefeedAddress("WETH_Pricefeed", address(wethPricefeed));

        // Deploy WBTC Pricefeed
        wbtcPricefeed = new Pricefeed(wbtcToken);
        _logPricefeedAddress("WBTC_Pricefeed", address(wbtcPricefeed));

        console.log("\n=== All pricefeeds deployed successfully ===");
        console.log("Total pricefeeds deployed: 12");
    }

    function _setInitialPrices() internal {
        console.log("\n=== Setting initial prices ===");
        
        // Set realistic mock prices (in USD with 8 decimals)
        // CADC: ~0.73 USD
        cadcPricefeed.setPrice(1, 73000000, block.timestamp, block.timestamp, 1);
        console.log("CADC price set to $0.73");

        // CNGN: ~0.00073 USD (Nigerian Naira)
        cngnPricefeed.setPrice(1, 730, block.timestamp, block.timestamp, 1);
        console.log("CNGN price set to $0.00073");

        // KRWT: ~0.00075 USD (Korean Won)
        krwtPricefeed.setPrice(1, 750, block.timestamp, block.timestamp, 1);
        console.log("KRWT price set to $0.00075");

        // TRYB: ~0.03 USD (Turkish Lira)
        trybPricefeed.setPrice(1, 3000000, block.timestamp, block.timestamp, 1);
        console.log("TRYB price set to $0.03");

        // MXNE: ~0.00005 USD (Mexican Peso)
        mxnePricefeed.setPrice(1, 5000, block.timestamp, block.timestamp, 1);
        console.log("MXNE price set to $0.00005");

        // XSGD: ~0.74 USD (Singapore Dollar)
        xsgdPricefeed.setPrice(1, 74000000, block.timestamp, block.timestamp, 1);
        console.log("XSGD price set to $0.74");

        // ZARP: ~0.055 USD (South African Rand)
        zarpPricefeed.setPrice(1, 5500000, block.timestamp, block.timestamp, 1);
        console.log("ZARP price set to $0.055");

        // IDRX: ~0.000067 USD (Indonesian Rupiah)
        idrxPricefeed.setPrice(1, 67, block.timestamp, block.timestamp, 1);
        console.log("IDRX price set to $0.000067");

        // EURC: ~1.08 USD (Euro)
        eurcPricefeed.setPrice(1, 108000000, block.timestamp, block.timestamp, 1);
        console.log("EURC price set to $1.08");

        // USDC: ~1.00 USD (US Dollar)
        usdcPricefeed.setPrice(1, 100000000, block.timestamp, block.timestamp, 1);
        console.log("USDC price set to $1.00");

        // WETH: ~3500 USD (Ethereum)
        wethPricefeed.setPrice(1, 350000000000, block.timestamp, block.timestamp, 1);
        console.log("WETH price set to $3500");

        // WBTC: ~95000 USD (Bitcoin)
        wbtcPricefeed.setPrice(1, 9500000000000, block.timestamp, block.timestamp, 1);
        console.log("WBTC price set to $95000");

        console.log("\n=== All initial prices set successfully ===");
    }

    function _logPricefeedAddress(string memory pricefeedName, address pricefeedAddress) internal view {
        string memory prefix = block.chainid == 8453 ? "BASE" : "ARB";
        console.log("address public %s_%s = %s;", prefix, pricefeedName, pricefeedAddress);
    }
}

// RUN COMMANDS:
// forge script DeployPricefeeds --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployPricefeeds --broadcast -vvv
// forge script DeployPricefeeds -vvv
