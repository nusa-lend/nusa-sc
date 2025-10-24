// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {bIB01} from "../src/mocks/bIB01.sol";
import {bCOIN} from "../src/mocks/bCOIN.sol";
import {bCSPX} from "../src/mocks/bCSPX.sol";
import {bIBTA} from "../src/mocks/bIBTA.sol";
import {bHIGH} from "../src/mocks/bHIGH.sol";
import {bTSLA} from "../src/mocks/bTSLA.sol";
import {bGOOGL} from "../src/mocks/bGOOGL.sol";
import {bNVDA} from "../src/mocks/bNVDA.sol";
import {bMSFT} from "../src/mocks/bMSFT.sol";
import {bGME} from "../src/mocks/bGME.sol";
import {bZPR1} from "../src/mocks/bZPR1.sol";

contract DeployTokenizedStocks is Script, HelperDeployment {
    // Tokenized Stocks instances
    bIB01 public bib01;
    bCOIN public bcoin;
    bCSPX public bcspx;
    bIBTA public bibta;
    bHIGH public bhigh;
    bTSLA public btsla;
    bGOOGL public bgoogle;
    bNVDA public bnvda;
    bMSFT public bmsft;
    bGME public bgme;
    bZPR1 public bzpr1;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(privateKey);

    function run() external {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));

        console.log("Deploying Tokenized Stocks with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(privateKey);

        _deployAllTokenizedStocks();
        // _mintInitialSupply();

        vm.stopBroadcast();
    }

    function _deployAllTokenizedStocks() internal {
        console.log("\n=== Deploying Tokenized Stocks ===");

        // Deploy bIB01 (Treasury Bond 0-1yr)
        bib01 = new bIB01();
        _logTokenAddress("bIB01", address(bib01));

        // Deploy bCOIN (Coinbase Global)
        bcoin = new bCOIN();
        _logTokenAddress("bCOIN", address(bcoin));

        // Deploy bCSPX (Core S&P 500)
        bcspx = new bCSPX();
        _logTokenAddress("bCSPX", address(bcspx));

        // Deploy bIBTA (Treasury Bond 1-3yr)
        bibta = new bIBTA();
        _logTokenAddress("bIBTA", address(bibta));

        // Deploy bHIGH (High Yield Corp Bond)
        bhigh = new bHIGH();
        _logTokenAddress("bHIGH", address(bhigh));

        // Deploy bTSLA (Tesla Inc)
        btsla = new bTSLA();
        _logTokenAddress("bTSLA", address(btsla));

        // Deploy bGOOGL (Alphabet Inc)
        bgoogle = new bGOOGL();
        _logTokenAddress("bGOOGL", address(bgoogle));

        // Deploy bNVDA (NVIDIA Corp)
        bnvda = new bNVDA();
        _logTokenAddress("bNVDA", address(bnvda));

        // Deploy bMSFT (Microsoft Corp)
        bmsft = new bMSFT();
        _logTokenAddress("bMSFT", address(bmsft));

        // Deploy bGME (GameStop Corp)
        bgme = new bGME();
        _logTokenAddress("bGME", address(bgme));

        // Deploy bZPR1 (1-3 Month T-Bill)
        bzpr1 = new bZPR1();
        _logTokenAddress("bZPR1", address(bzpr1));

        console.log("\n=== All Tokenized Stocks deployed successfully ===");
        console.log("Total tokenized stocks deployed: 11");
    }

    function _mintInitialSupply() internal {
        console.log("\n=== Minting initial supply ===");
        
        uint256 initialSupply = 1000000 * 1e18; // 1M tokens each
        
        // Mint initial supply for all tokens
        bib01.mint(deployer, initialSupply);
        console.log("bIB01: Minted", initialSupply / 1e18, "tokens");

        bcoin.mint(deployer, initialSupply);
        console.log("bCOIN: Minted", initialSupply / 1e18, "tokens");

        bcspx.mint(deployer, initialSupply);
        console.log("bCSPX: Minted", initialSupply / 1e18, "tokens");

        bibta.mint(deployer, initialSupply);
        console.log("bIBTA: Minted", initialSupply / 1e18, "tokens");

        bhigh.mint(deployer, initialSupply);
        console.log("bHIGH: Minted", initialSupply / 1e18, "tokens");

        btsla.mint(deployer, initialSupply);
        console.log("bTSLA: Minted", initialSupply / 1e18, "tokens");

        bgoogle.mint(deployer, initialSupply);
        console.log("bGOOGL: Minted", initialSupply / 1e18, "tokens");

        bnvda.mint(deployer, initialSupply);
        console.log("bNVDA: Minted", initialSupply / 1e18, "tokens");

        bmsft.mint(deployer, initialSupply);
        console.log("bMSFT: Minted", initialSupply / 1e18, "tokens");

        bgme.mint(deployer, initialSupply);
        console.log("bGME: Minted", initialSupply / 1e18, "tokens");

        bzpr1.mint(deployer, initialSupply);
        console.log("bZPR1: Minted", initialSupply / 1e18, "tokens");

        console.log("\n=== Initial supply minting completed ===");
    }

    function _logTokenAddress(string memory tokenName, address tokenAddress) internal view {
        string memory prefix = block.chainid == 8453 ? "BASE" : "ARB";
        console.log("address public %s_%s = %s;", prefix, tokenName, tokenAddress);
    }
}

// RUN COMMANDS:
// forge script DeployTokenizedStocks --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployTokenizedStocks --broadcast -vvv
// forge script DeployTokenizedStocks -vvv
