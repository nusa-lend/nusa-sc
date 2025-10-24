// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Helper} from "../src/devtools/Helper.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {WBTC} from "../src/mocks/WBTC.sol";
import {Router} from "../src/Router.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OAppBorrow} from "../src/L0/OAppBorrow.sol";
import {IOAppBorrow} from "../src/interfaces/IOAppBorrow.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {Pricefeed} from "../src/Pricefeed.sol";
import {CADC} from "../src/mocks/CADC.sol";
import {CNGN} from "../src/mocks/CNGN.sol";
import {KRWT} from "../src/mocks/KRWT.sol";
import {TRYB} from "../src/mocks/TRYB.sol";
import {MXNE} from "../src/mocks/MXNE.sol";
import {XSGD} from "../src/mocks/XSGD.sol";
import {ZARP} from "../src/mocks/ZARP.sol";
import {IDRX} from "../src/mocks/IDRX.sol";
import {EURC} from "../src/mocks/EURC.sol";
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

contract Nusa is Script, Helper, HelperDeployment {
    using OptionsBuilder for bytes;

    USDC public usdc;
    WETH public weth;
    WBTC public wbtc;
    CADC public cadc;
    CNGN public cngn;
    KRWT public krwt;
    TRYB public tryb;
    MXNE public mxne;
    XSGD public xsgd;
    ZARP public zarp;
    IDRX public idrx;
    EURC public eurc;

    // Tokenized Stocks
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

    address public usdc_deployed;
    address public weth_deployed;
    address public wbtc_deployed;
    address public cadc_deployed;
    address public cngn_deployed;
    address public krwt_deployed;
    address public tryb_deployed;
    address public mxne_deployed;
    address public xsgd_deployed;
    address public zarp_deployed;
    address public idrx_deployed;
    address public eurc_deployed;

    // Tokenized Stocks deployed addresses
    address public bib01_deployed;
    address public bcoin_deployed;
    address public bcspx_deployed;
    address public bibta_deployed;
    address public bhigh_deployed;
    address public btsla_deployed;
    address public bgoogle_deployed;
    address public bnvda_deployed;
    address public bmsft_deployed;
    address public bgme_deployed;
    address public bzpr1_deployed;
    address public tokenDataStream_deployed;
    address public lendingPool_deployed;
    address public oappBorrow_deployed;
    address public router_deployed;

    Router public router;
    IsHealthy public isHealthy;
    TokenDataStream public tokenDataStream;
    LendingPool public lendingPool;
    ERC1967Proxy public proxy;
    OAppBorrow public oappBorrow;
    Pricefeed public pricefeed;

    uint32 dstEid0;
    uint32 dstEid1;

    address endpoint;
    address oapp;
    address sendLib;
    address receiveLib;
    address dvn1;
    address dvn2;
    address executor;
    uint32 srcEid;
    uint32 gracePeriod;

    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;
    uint32 constant RECEIVE_CONFIG_TYPE = 2;
    uint16 constant SEND = 1; // Message type for send function

    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address public owner = vm.envAddress("PUBLIC_KEY");

    bool public isDeployed;

    function run() public {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);

        isDeployed = _isDeployed(true);

        _deployMockToken();
        // _deployNusaCore();
        // _activateToken();
        // _getUtils(); // Initialize endpoint and LayerZero config variables
        // _deployOAppBorrow();
        // _setLibraries();
        // _setSendConfig();
        // _setReceiveConfig();
        // _setPeers();
        // _setEnforcedOptions();
        // _setChainId();

        // router.setChainIdToLzEid(block.chainid == 8453 ? 42161 : 8453, dstEid1);
        // router.setChainIdToOApp(8453, address(oappBorrow));

        // Router(router_deployed).setChainIdToLzEid(block.chainid == 8453 ? 42161 : 8453, dstEid1);
        // Router(router_deployed).setChainIdToOApp(8453, address(oappBorrow_deployed));

        vm.stopBroadcast();
    }

    function _isDeployed(bool _deployed) internal returns (bool) {
        if (_deployed) {
            usdc_deployed = block.chainid == 8453 ? BASE_USDC : ARB_USDC;
            weth_deployed = block.chainid == 8453 ? BASE_WETH : ARB_WETH;
            wbtc_deployed = block.chainid == 8453 ? BASE_WBTC : ARB_WBTC;

            tokenDataStream_deployed = block.chainid == 8453 ? BASE_TokenDataStream : ARB_TokenDataStream;
            lendingPool_deployed = block.chainid == 8453 ? BASE_Proxy : ARB_Proxy;
            oappBorrow_deployed = block.chainid == 8453 ? BASE_OAppBorrow : ARB_OAppBorrow;
            router_deployed = block.chainid == 8453 ? BASE_Router : ARB_Router;
        }
        return _deployed;
    }

    function _deployMockToken() internal {
        if (!isDeployed) {
            usdc = new USDC();
            block.chainid == 8453
                ? console.log("address public BASE_USDC = %s;", address(usdc))
                : console.log("address public ARB_USDC = %s;", address(usdc));
            weth = new WETH();
            block.chainid == 8453
                ? console.log("address public BASE_WETH = %s;", address(weth))
                : console.log("address public ARB_WETH = %s;", address(weth));
            wbtc = new WBTC();
            block.chainid == 8453
                ? console.log("address public BASE_WBTC = %s;", address(wbtc))
                : console.log("address public ARB_WBTC = %s;", address(wbtc));
        } else {
            usdc = block.chainid == 8453 ? USDC(BASE_USDC) : USDC(ARB_USDC);
            weth = block.chainid == 8453 ? WETH(BASE_WETH) : WETH(ARB_WETH);
            wbtc = block.chainid == 8453 ? WBTC(BASE_WBTC) : WBTC(ARB_WBTC);
            cadc = block.chainid == 8453 ? CADC(BASE_CADC) : CADC(ARB_CADC);
            cngn = block.chainid == 8453 ? CNGN(BASE_CNGN) : CNGN(ARB_CNGN);
            krwt = block.chainid == 8453 ? KRWT(BASE_KRWT) : KRWT(ARB_KRWT);
            tryb = block.chainid == 8453 ? TRYB(BASE_TRYB) : TRYB(ARB_TRYB);
            mxne = block.chainid == 8453 ? MXNE(BASE_MXNE) : MXNE(ARB_MXNE);
            xsgd = block.chainid == 8453 ? XSGD(BASE_XSGD) : XSGD(ARB_XSGD);
            zarp = block.chainid == 8453 ? ZARP(BASE_ZARP) : ZARP(ARB_ZARP);
            idrx = block.chainid == 8453 ? IDRX(BASE_IDRX) : IDRX(ARB_IDRX);
            eurc = block.chainid == 8453 ? EURC(BASE_EURC) : EURC(ARB_EURC);

            // Tokenized Stocks
            bib01 = block.chainid == 8453 ? bIB01(BASE_bIB01) : bIB01(ARB_bIB01);
            bcoin = block.chainid == 8453 ? bCOIN(BASE_bCOIN) : bCOIN(ARB_bCOIN);
            bcspx = block.chainid == 8453 ? bCSPX(BASE_bCSPX) : bCSPX(ARB_bCSPX);
            bibta = block.chainid == 8453 ? bIBTA(BASE_bIBTA) : bIBTA(ARB_bIBTA);
            bhigh = block.chainid == 8453 ? bHIGH(BASE_bHIGH) : bHIGH(ARB_bHIGH);
            btsla = block.chainid == 8453 ? bTSLA(BASE_bTSLA) : bTSLA(ARB_bTSLA);
            bgoogle = block.chainid == 8453 ? bGOOGL(BASE_bGOOGL) : bGOOGL(ARB_bGOOGL);
            bnvda = block.chainid == 8453 ? bNVDA(BASE_bNVDA) : bNVDA(ARB_bNVDA);
            bmsft = block.chainid == 8453 ? bMSFT(BASE_bMSFT) : bMSFT(ARB_bMSFT);
            bgme = block.chainid == 8453 ? bGME(BASE_bGME) : bGME(ARB_bGME);
            bzpr1 = block.chainid == 8453 ? bZPR1(BASE_bZPR1) : bZPR1(ARB_bZPR1);
        }
        if (!isDeployed) {
            tokenDataStream = new TokenDataStream();
        } else {
            tokenDataStream = TokenDataStream(tokenDataStream_deployed);
        }
        block.chainid == 8453
            ? console.log("address public BASE_TokenDataStream = %s;", address(tokenDataStream))
            : console.log("address public ARB_TokenDataStream = %s;", address(tokenDataStream));

        if (block.chainid == 8453) {
            // tokenDataStream.setTokenPriceFeed(address(usdc), address(BASE_USDC_USD));
            // tokenDataStream.setTokenPriceFeed(address(weth), address(BASE_ETH_USD));
            // tokenDataStream.setTokenPriceFeed(address(cadc), address(BASE_CADC_USD));
            // tokenDataStream.setTokenPriceFeed(address(cngn), address(BASE_CNGN_USD));
            // tokenDataStream.setTokenPriceFeed(address(krwt), address(BASE_KRWT_USD));
            // tokenDataStream.setTokenPriceFeed(address(tryb), address(BASE_TRYB_USD));
            // tokenDataStream.setTokenPriceFeed(address(mxne), address(BASE_MXNE_USD));
            // tokenDataStream.setTokenPriceFeed(address(xsgd), address(BASE_XSGD_USD));
            // tokenDataStream.setTokenPriceFeed(address(zarp), address(BASE_ZARP_USD));
            // tokenDataStream.setTokenPriceFeed(address(idrx), address(BASE_IDRX_USD));
            // tokenDataStream.setTokenPriceFeed(address(eurc), address(BASE_EURC_USD));

            tokenDataStream.setTokenPriceFeed(address(bib01), address(BASE_bIB01_USD));
            tokenDataStream.setTokenPriceFeed(address(bcoin), address(BASE_bCOIN_USD));
            tokenDataStream.setTokenPriceFeed(address(bcspx), address(BASE_bCSPX_USD));
            tokenDataStream.setTokenPriceFeed(address(bibta), address(BASE_bIBTA_USD));
            tokenDataStream.setTokenPriceFeed(address(bhigh), address(BASE_bHIGH_USD));
            tokenDataStream.setTokenPriceFeed(address(btsla), address(BASE_bTSLA_USD));
            tokenDataStream.setTokenPriceFeed(address(bgoogle), address(BASE_bGOOGL_USD));
            tokenDataStream.setTokenPriceFeed(address(bnvda), address(BASE_bNVDA_USD));
            tokenDataStream.setTokenPriceFeed(address(bmsft), address(BASE_bMSFT_USD));
            tokenDataStream.setTokenPriceFeed(address(bgme), address(BASE_bGME_USD));
            tokenDataStream.setTokenPriceFeed(address(bzpr1), address(BASE_bZPR1_USD));

            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(usdc), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(weth), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(cadc), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(cngn), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(krwt), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(tryb), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(mxne), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(xsgd), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(zarp), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(idrx), true);
            // LendingPool(payable(lendingPool_deployed)).setTokenActive(address(eurc), true);

            // Activate Tokenized Stocks
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bib01), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bcoin), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bcspx), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bibta), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bhigh), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(btsla), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bgoogle), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bnvda), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bmsft), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bgme), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bzpr1), true);
        } else if (block.chainid == 42161) {
            tokenDataStream.setTokenPriceFeed(address(usdc), address(ARB_USDC_USD));
            tokenDataStream.setTokenPriceFeed(address(weth), address(ARB_ETH_USD));
            tokenDataStream.setTokenPriceFeed(address(cadc), address(ARB_CADC_USD));
            tokenDataStream.setTokenPriceFeed(address(cngn), address(ARB_CNGN_USD));
            tokenDataStream.setTokenPriceFeed(address(krwt), address(ARB_KRWT_USD));
            tokenDataStream.setTokenPriceFeed(address(tryb), address(ARB_TRYB_USD));
            tokenDataStream.setTokenPriceFeed(address(mxne), address(ARB_MXNE_USD));
            tokenDataStream.setTokenPriceFeed(address(xsgd), address(ARB_XSGD_USD));
            tokenDataStream.setTokenPriceFeed(address(zarp), address(ARB_ZARP_USD));
            tokenDataStream.setTokenPriceFeed(address(idrx), address(ARB_IDRX_USD));
            tokenDataStream.setTokenPriceFeed(address(eurc), address(ARB_EURC_USD));

            tokenDataStream.setTokenPriceFeed(address(bib01), address(ARB_bIB01_USD));
            tokenDataStream.setTokenPriceFeed(address(bcoin), address(ARB_bCOIN_USD));
            tokenDataStream.setTokenPriceFeed(address(bcspx), address(ARB_bCSPX_USD));
            tokenDataStream.setTokenPriceFeed(address(bibta), address(ARB_bIBTA_USD));
            tokenDataStream.setTokenPriceFeed(address(bhigh), address(ARB_bHIGH_USD));
            tokenDataStream.setTokenPriceFeed(address(btsla), address(ARB_bTSLA_USD));
            tokenDataStream.setTokenPriceFeed(address(bgoogle), address(ARB_bGOOGL_USD));
            tokenDataStream.setTokenPriceFeed(address(bnvda), address(ARB_bNVDA_USD));
            tokenDataStream.setTokenPriceFeed(address(bmsft), address(ARB_bMSFT_USD));
            tokenDataStream.setTokenPriceFeed(address(bgme), address(ARB_bGME_USD));
            tokenDataStream.setTokenPriceFeed(address(bzpr1), address(ARB_bZPR1_USD));

            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(usdc), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(weth), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(cadc), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(cngn), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(krwt), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(tryb), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(mxne), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(xsgd), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(zarp), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(idrx), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(eurc), true);

            // Activate Tokenized Stocks
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bib01), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bcoin), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bcspx), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bibta), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bhigh), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(btsla), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bgoogle), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bnvda), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bmsft), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bgme), true);
            LendingPool(payable(lendingPool_deployed)).setTokenActive(address(bzpr1), true);
        }
    }

    function _deployNusaCore() internal {
        router = new Router();
        block.chainid == 8453
            ? console.log("address public BASE_Router = %s;", address(router))
            : console.log("address public ARB_Router = %s;", address(router));
        isHealthy = new IsHealthy(address(router));
        block.chainid == 8453
            ? console.log("address public BASE_IsHealthy = %s;", address(isHealthy))
            : console.log("address public ARB_IsHealthy = %s;", address(isHealthy));

        lendingPool = new LendingPool();
        block.chainid == 8453
            ? console.log("address public BASE_LendingPool = %s;", address(lendingPool))
            : console.log("address public ARB_LendingPool = %s;", address(lendingPool));
        bytes memory data = abi.encodeWithSelector(lendingPool.initialize.selector);
        proxy = new ERC1967Proxy(address(lendingPool), data);
        block.chainid == 8453
            ? console.log("address public BASE_Proxy = %s;", address(proxy))
            : console.log("address public ARB_Proxy = %s;", address(proxy));
        lendingPool = LendingPool(payable(proxy));
        lendingPool.setRouter(address(router));

        router.setTokenDataStream(address(tokenDataStream));
        router.setIsHealthy(address(isHealthy));
        router.setLendingPool(address(lendingPool));
    }

    function _activateToken() internal {
        lendingPool.setTokenActive(address(weth), true);
        lendingPool.setTokenActive(address(usdc), true);
        lendingPool.setToken(address(weth), true);
        lendingPool.setToken(address(usdc), true);

        lendingPool.setBorrowLtv(address(weth), 0.8e18); // Set borrow LTV (80% = 0.8e18)
        lendingPool.setBorrowLtv(address(usdc), 0.8e18); // Set borrow LTV (80% = 0.8e18)
    }

    function _getUtils() internal {
        if (block.chainid == 8453) {
            endpoint = BASE_LZ_ENDPOINT;
            sendLib = BASE_SEND_LIB;
            receiveLib = BASE_RECEIVE_LIB;
            dvn1 = BASE_DVN1;
            dvn2 = BASE_DVN2;
            executor = BASE_EXECUTOR;
            srcEid = BASE_EID;
            dstEid0 = BASE_EID;
            dstEid1 = ARB_EID;
            gracePeriod = uint32(0);
        } else if (block.chainid == 42161) {
            endpoint = ARB_LZ_ENDPOINT;
            sendLib = ARB_SEND_LIB;
            receiveLib = ARB_RECEIVE_LIB;
            dvn1 = ARB_DVN1;
            dvn2 = ARB_DVN2;
            executor = ARB_EXECUTOR;
            srcEid = ARB_EID;
            dstEid0 = ARB_EID;
            dstEid1 = BASE_EID;
            gracePeriod = uint32(0);
        }
    }

    /// @notice Helper function to convert fixed-size array to dynamic array
    function _toDynamicArray(address[2] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](2);
        dynamicArray[0] = fixedArray[0];
        dynamicArray[1] = fixedArray[1];
        return dynamicArray;
    }

    function _toDynamicArray1(address[1] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](1);
        dynamicArray[0] = fixedArray[0];
        return dynamicArray;
    }

    function _deployOAppBorrow() internal {
        oappBorrow = new OAppBorrow(endpoint, owner);
        oappBorrow.setLendingPool(address(lendingPool));
        block.chainid == 8453
            ? console.log("address public BASE_OAppBorrow = %s;", address(oappBorrow))
            : console.log("address public ARB_OAppBorrow = %s;", address(oappBorrow));
    }

    /// @notice Set send and receive libraries for LayerZero endpoint
    function _setLibraries() internal {
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oappBorrow), dstEid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oappBorrow), srcEid, receiveLib, gracePeriod);
    }

    /// @notice Set send configuration (ULN + Executor)
    function _setSendConfig() internal {
        UlnConfig memory uln = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _toDynamicArray([dvn1, dvn2]),
            optionalDVNs: new address[](0)
        });

        ExecutorConfig memory exec = ExecutorConfig({maxMessageSize: 10000, executor: executor});
        bytes memory encodedUln = abi.encode(uln);
        bytes memory encodedExec = abi.encode(exec);

        SetConfigParam[] memory params = new SetConfigParam[](4);
        params[0] = SetConfigParam(dstEid0, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[1] = SetConfigParam(dstEid0, ULN_CONFIG_TYPE, encodedUln);
        params[2] = SetConfigParam(dstEid1, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[3] = SetConfigParam(dstEid1, ULN_CONFIG_TYPE, encodedUln);

        ILayerZeroEndpointV2(endpoint).setConfig(address(oappBorrow), sendLib, params);
    }

    /// @notice Set receive configuration (ULN)
    function _setReceiveConfig() internal {
        UlnConfig memory uln = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _toDynamicArray([dvn1, dvn2]),
            optionalDVNs: new address[](0)
        });

        bytes memory encodedUln = abi.encode(uln);
        SetConfigParam[] memory params = new SetConfigParam[](2);
        params[0] = SetConfigParam(dstEid0, RECEIVE_CONFIG_TYPE, encodedUln);
        params[1] = SetConfigParam(dstEid1, RECEIVE_CONFIG_TYPE, encodedUln);

        ILayerZeroEndpointV2(endpoint).setConfig(address(oappBorrow), receiveLib, params);
    }

    /// @notice Set peer connections between OApps on different chains
    function _setPeers() internal {
        // Set peer to itself for same chain
        oappBorrow.setPeer(dstEid0, bytes32(uint256(uint160(address(oappBorrow)))));
        // OAppBorrow(oappBorrow_deployed).setPeer(dstEid0, bytes32(uint256(uint160(address(oappBorrow_deployed)))));

        // Set peer to remote oappBorrow for cross-chain (use same address for testing)
        // oappBorrow.setPeer(dstEid1, bytes32(uint256(uint160(address(oappBorrow)))));
    }

    /// @notice Set enforced execution options for specific message types
    function _setEnforcedOptions() internal {
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(300000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(300000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: dstEid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: dstEid1, msgType: SEND, options: options2});

        // oappBorrow.setEnforcedOptions(enforcedOptions);
        OAppBorrow(oappBorrow_deployed).setEnforcedOptions(enforcedOptions);
    }

    function _setChainId() internal {
        lendingPool.setChainId(block.chainid == 8453 ? 42161 : 8453);
        // LendingPool(payable(lendingPool_deployed)).setChainId(block.chainid == 8453 ? 42161 : 8453);
    }
}

// RUN
// forge script Nusa --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script Nusa --broadcast -vvv
// forge script Nusa -vvv
// forge script Nusa --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY --with-gas-price 1gwei
// forge script Nusa -vvv --with-gas-price 18gwei
