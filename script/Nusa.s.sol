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

contract Nusa is Script, Helper, HelperDeployment {
    using OptionsBuilder for bytes;

    USDC public usdc;
    WETH public weth;
    WBTC public wbtc;

    address public usdc_deployed;
    address public weth_deployed;
    address public wbtc_deployed;
    address public lendingPool_deployed;
    address public oappBorrow_deployed;
    address public router_deployed;

    Router public router;
    IsHealthy public isHealthy;
    TokenDataStream public tokenDataStream;
    LendingPool public lendingPool;
    ERC1967Proxy public proxy;
    OAppBorrow public oappBorrow;
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

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(privateKey);

        usdc_deployed = block.chainid == 8453 ? BASE_USDC : HYPE_USDC;
        weth_deployed = block.chainid == 8453 ? BASE_WETH : HYPE_WETH;
        wbtc_deployed = block.chainid == 8453 ? BASE_WBTC : HYPE_WBTC;
        lendingPool_deployed = block.chainid == 8453 ? BASE_LendingPool : address(0);
        oappBorrow_deployed = block.chainid == 8453 ? BASE_OAppBorrow : address(0);
        router_deployed = block.chainid == 8453 ? BASE_Router : address(0);
        // _deployMockToken();
        // _deployNusaCore();
        // _activateToken();
        _getUtils(); // Initialize endpoint and LayerZero config variables
        // _deployOAppBorrow();
        // _setLibraries();
        // _setSendConfig();
        // _setReceiveConfig();
        _setPeers();
        _setEnforcedOptions();
        // _setChainId();

        // router.setChainIdToLzEid(block.chainid == 8453 ? 999 : 8453, dstEid1);
        // router.setChainIdToOApp(8453, address(oappBorrow));

        Router(router_deployed).setChainIdToLzEid(block.chainid == 8453 ? 999 : 8453, dstEid1);
        Router(router_deployed).setChainIdToOApp(8453, address(oappBorrow_deployed));

        vm.stopBroadcast();
    }

    function _deployMockToken() internal {
        usdc = new USDC();
        weth = new WETH();
        wbtc = new WBTC();
        // usdc = block.chainid == 8453 ? BASE_USDC : HYPE_USDC;
        // weth = block.chainid == 8453 ? BASE_WETH : HYPE_WETH;
        // wbtc = block.chainid == 8453 ? BASE_WBTC : HYPE_WBTC;
        tokenDataStream = new TokenDataStream();

        tokenDataStream.setTokenPriceFeed(address(usdc), block.chainid == 8453 ? address(BASE_USDC_USD) : address(0));
        tokenDataStream.setTokenPriceFeed(address(weth), block.chainid == 8453 ? address(BASE_ETH_USD) : address(0));

        console.log("address public BASE_USDC = %s;", address(usdc));
        console.log("address public BASE_WETH = %s;", address(weth));
        console.log("address public BASE_WBTC = %s;", address(wbtc));
        console.log("address public BASE_TokenDataStream = %s;", address(tokenDataStream));
    }

    function _deployNusaCore() internal {
        router = new Router();
        console.log("address public BASE_Router = %s;", address(router));
        isHealthy = new IsHealthy(address(router));
        console.log("address public BASE_IsHealthy = %s;", address(isHealthy));

        lendingPool = new LendingPool();
        console.log("address public BASE_LendingPool = %s;", address(lendingPool));
        bytes memory data = abi.encodeWithSelector(lendingPool.initialize.selector);
        proxy = new ERC1967Proxy(address(lendingPool), data);
        console.log("address public BASE_Proxy = %s;", address(proxy));
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
            dstEid1 = HYPE_EID;
            gracePeriod = uint32(0);
        } else if (block.chainid == 999) {
            endpoint = HYPE_LZ_ENDPOINT;
            sendLib = HYPE_SEND_LIB;
            receiveLib = HYPE_RECEIVE_LIB;
            dvn1 = HYPE_DVN1;
            dvn2 = HYPE_DVN2;
            executor = HYPE_EXECUTOR;
            srcEid = HYPE_EID;
            dstEid0 = HYPE_EID;
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
        console.log("address public BASE_OAppBorrow = %s;", address(oappBorrow));
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
        // oappBorrow.setPeer(dstEid0, bytes32(uint256(uint160(address(oappBorrow)))));
        OAppBorrow(oappBorrow_deployed).setPeer(dstEid0, bytes32(uint256(uint160(address(oappBorrow_deployed)))));

        // Set peer to remote oappBorrow for cross-chain (use same address for testing)
        // oappBorrow.setPeer(dstEid1, bytes32(uint256(uint160(address(oappBorrow)))));
    }

    /// @notice Set enforced execution options for specific message types
    function _setEnforcedOptions() internal {
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: dstEid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: dstEid1, msgType: SEND, options: options2});

        // oappBorrow.setEnforcedOptions(enforcedOptions);
        OAppBorrow(oappBorrow_deployed).setEnforcedOptions(enforcedOptions);
    }

    function _setChainId() internal {
        // lendingPool.setChainId(block.chainid == 8453 ? 999 : 8453);
        LendingPool(payable(lendingPool_deployed)).setChainId(block.chainid == 8453 ? 999 : 8453);
    }
}

// RUN
// forge script Nusa --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script Nusa -vvv
