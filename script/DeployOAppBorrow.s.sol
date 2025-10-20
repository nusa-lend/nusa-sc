// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {OAppBorrow} from "../src/L0/OAppBorrow.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {Router} from "../src/Router.sol";

contract DeployOAppBorrowScript is Script, HelperDeployment {
    using OptionsBuilder for bytes;

    OAppBorrow public oappBorrow;
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(privateKey);

    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;
    uint32 constant RECEIVE_CONFIG_TYPE = 2;
    uint16 constant SEND = 1; // Message type for send function

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

    address oappBorrow_deployed;
    address oapp1;
    address oapp2;

    function run() external {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));

        console.log("Deploying OAppBorrow with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(privateKey);

        oappBorrow_deployed = block.chainid == 8453 ? BASE_OAppBorrow : ARB_OAppBorrow;
        oapp1 = block.chainid == 8453 ? BASE_OAppBorrow : ARB_OAppBorrow;
        oapp2 = block.chainid == 8453 ? ARB_OAppBorrow : BASE_OAppBorrow;

        _getUtils();
        // _deployOAppBorrow();

        // _setLibraries();
        // _setSendConfig();
        // _setReceiveConfig();
        _setPeers();
        _setEnforcedOptions();
        _setRouter(block.chainid == 8453 ? BASE_Router : ARB_Router);
        _setOApp();
        vm.stopBroadcast();
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

    function _deployOAppBorrow() internal {
        _getUtils();
        oappBorrow = new OAppBorrow(endpoint, deployer);
        oappBorrow.setLendingPool(block.chainid == 8453 ? BASE_Proxy : ARB_Proxy);

        block.chainid == 8453
            ? console.log("address public BASE_OAppBorrow = %s;", address(oappBorrow))
            : console.log("address public ARB_OAppBorrow = %s;", address(oappBorrow));
    }

    function _setLibraries() internal {
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oappBorrow), dstEid0, sendLib);
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
        OAppBorrow(oappBorrow_deployed).setPeer(dstEid0, bytes32(uint256(uint160(address(oapp1)))));

        // Set peer to remote oappBorrow for cross-chain (use same address for testing)
        // oappBorrow.setPeer(dstEid1, bytes32(uint256(uint160(address(oappBorrow)))));
        OAppBorrow(oappBorrow_deployed).setPeer(dstEid1, bytes32(uint256(uint160(address(oapp2)))));
    }

    /// @notice Set enforced execution options for specific message types
    function _setEnforcedOptions() internal {
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(800000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(1000000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: dstEid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: dstEid1, msgType: SEND, options: options2});

        // oappBorrow.setEnforcedOptions(enforcedOptions);
        OAppBorrow(oappBorrow_deployed).setEnforcedOptions(enforcedOptions);
    }

    function _setRouter(address _router) internal {
        // oappBorrow.setRouter(_router);
        block.chainid == 8453
            ? OAppBorrow(BASE_OAppBorrow).setRouter(_router)
            : OAppBorrow(ARB_OAppBorrow).setRouter(_router);
    }

    function _setOApp() internal {
        Router(block.chainid == 8453 ? BASE_Router : ARB_Router).setChainIdToOApp(
            block.chainid == 8453 ? 8453 : 42161, block.chainid == 8453 ? BASE_OAppBorrow : ARB_OAppBorrow
        );
    }

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
}

// RUN
// forge script DeployOAppBorrowScript -vvv --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployOAppBorrowScript -vvv --broadcast
// forge script DeployOAppBorrowScript -vvv
